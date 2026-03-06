#!/usr/bin/env bash
input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // ""')
raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
lines_added=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
lines_removed=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
tokens_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
tokens_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')

cwd="${raw_cwd/#$HOME/~}"

# Git: find repo from raw cwd
branch=""
repo_name=""
if [ -n "$raw_cwd" ] && git -C "$raw_cwd" rev-parse --git-dir >/dev/null 2>&1; then
  branch=$(git -C "$raw_cwd" symbolic-ref --short HEAD 2>/dev/null || git -C "$raw_cwd" rev-parse --short HEAD 2>/dev/null)
  repo_root=$(git -C "$raw_cwd" rev-parse --show-toplevel 2>/dev/null)
  repo_name=$(basename "$repo_root" 2>/dev/null)
fi

cost_fmt=$(printf '%.2f' "$cost" 2>/dev/null)

# Format uptime from ms
total_secs=$(( duration_ms / 1000 ))
if [ "$total_secs" -ge 3600 ] 2>/dev/null; then
  uptime_fmt="$(( total_secs / 3600 ))h$(( (total_secs % 3600) / 60 ))m"
elif [ "$total_secs" -ge 60 ] 2>/dev/null; then
  uptime_fmt="$(( total_secs / 60 ))m$(( total_secs % 60 ))s"
else
  uptime_fmt="${total_secs}s"
fi

# Format token counts (k suffix)
fmt_tokens() {
  if [ "$1" -ge 1000 ] 2>/dev/null; then
    printf '%s.%sk' "$(( $1 / 1000 ))" "$(( ($1 % 1000) / 100 ))"
  else
    echo "$1"
  fi
}
tokens_in_fmt=$(fmt_tokens "$tokens_in")
tokens_out_fmt=$(fmt_tokens "$tokens_out")

# Visual progress bar (colored per-cell against segment bg)
filled=$(( pct / 10 ))
empty=$(( 10 - filled ))

# Nerd Font icons as raw UTF-8 bytes
icon_model=$(printf '\xef\x84\x92')
icon_folder=$(printf '\xef\x81\xbc')
icon_cost=$(printf '\xef\x85\x95')
icon_add=$(printf '\xef\x91\x97')
icon_remove=$(printf '\xef\x91\x98')
icon_branch=$(printf '\xee\x82\xa0')
icon_gauge=$(printf '\xef\x83\xa4')
icon_clock=$(printf '\xef\x80\x97')
icon_tokens=$(printf '\xef\x8b\xa1')

# ANSI colors via raw ESC byte
ESC=$(printf '\x1b')
RST="${ESC}[0m"
FG_W="${ESC}[38;2;255;255;255m"

# True color helpers
bg_rgb() { printf '%s[48;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"; }
fg_rgb() { printf '%s[38;2;%s;%s;%sm' "$ESC" "$1" "$2" "$3"; }

# Gradient blend between two bg colors (4 steps)
lerp() { echo $(( $1 + ($2 - $1) * $3 / 4 )); }
blend() {
  local r1=$1 g1=$2 b1=$3 r2=$4 g2=$5 b2=$6
  local result=""
  for s in 1 2 3; do
    local r=$(lerp $r1 $r2 $s) g=$(lerp $g1 $g2 $s) b=$(lerp $b1 $b2 $s)
    result+="$(bg_rgb $r $g $b) "
  done
  printf '%s' "$result"
}

# Rainbow segment colors (RGB)
# rose -> orange -> gold -> green/orange/red -> teal -> purple
R_MODEL="180 60 100"
R_FOLDER="190 110 40"
R_BRANCH="175 150 30"
R_CHANGES="40 135 160"
R_TOKENS="60 100 170"
R_UPTIME="130 60 150"
R_COST="105 55 165"

# Context bar color based on usage
if [ "$pct" -ge 80 ] 2>/dev/null; then   R_BAR="175 50 50"
elif [ "$pct" -ge 50 ] 2>/dev/null; then  R_BAR="185 125 30"
else                                       R_BAR="45 145 65"
fi

# Terminal background color (Ghostty default)
R_TERM="28 28 28"

face='¯\_(ツ)_/¯'
R_FACE="160 80 140"

# Build line 1: model, context bar, changes, tokens, uptime, cost, face
out=""
out+="$(blend $R_TERM $R_MODEL)$(bg_rgb $R_MODEL)${FG_W} ${icon_model} ${model} "

# Build progress bar: bright filled, dark empty
read -r br bg bb <<< "$R_BAR"
dim_r=$(( br / 3 ))
dim_g=$(( bg / 3 ))
dim_b=$(( bb / 3 ))
FG_DIM="$(fg_rgb $dim_r $dim_g $dim_b)"
bar=""
for ((i=0; i<filled; i++)); do bar+="${FG_W}━"; done
for ((i=0; i<empty; i++)); do bar+="${FG_DIM}━"; done
out+="$(blend $R_MODEL $R_BAR)$(bg_rgb $R_BAR)${FG_W} ${icon_gauge} ${pct}% ${bar} "
out+="$(blend $R_BAR $R_CHANGES)$(bg_rgb $R_CHANGES)${FG_W} +${lines_added} -${lines_removed} "
out+="$(blend $R_CHANGES $R_TOKENS)$(bg_rgb $R_TOKENS)${FG_W} ${icon_tokens} ${tokens_in_fmt}/${tokens_out_fmt} "
out+="$(blend $R_TOKENS $R_UPTIME)$(bg_rgb $R_UPTIME)${FG_W} ${icon_clock} ${uptime_fmt} "
out+="$(blend $R_UPTIME $R_COST)$(bg_rgb $R_COST)${FG_W} ${icon_cost}${cost_fmt} "
out+="$(blend $R_COST $R_FACE)$(bg_rgb $R_FACE)${FG_W} ${face} "
out+="$(blend $R_FACE $R_TERM)${RST}"

# Build line 2: folder and branch
line2=""
line2+="$(blend $R_TERM $R_FOLDER)$(bg_rgb $R_FOLDER)${FG_W} ${icon_folder} ${cwd} "

if [ -n "$branch" ]; then
  line2+="$(blend $R_FOLDER $R_BRANCH)$(bg_rgb $R_BRANCH)${FG_W} ${icon_branch} "
  [ -n "$repo_name" ] && line2+="${repo_name}:" || true
  line2+="${branch} "
  line2+="$(blend $R_BRANCH $R_TERM)${RST}"
else
  line2+="$(blend $R_FOLDER $R_TERM)${RST}"
fi

printf '%s\n%s' "$out" "$line2"
