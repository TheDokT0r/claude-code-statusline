# Claude Code Statusline

A custom statusline for [Claude Code](https://claude.com/claude-code) with gradient segments, Nerd Font icons, and a two-line layout.

![screenshot](screenshot.png)

## Features

**Line 1:** Model name, context window usage bar, lines changed, token counts, session uptime, cost, and a shrug face

**Line 2:** Current directory and git branch with repo name

- Gradient transitions between segments using true color (24-bit) ANSI
- Context bar changes color based on usage: green (<50%), orange (50-80%), red (>80%)
- Progress bar with bright/dim cells for filled/empty
- Token counts formatted with `k` suffix
- Git branch detection from working directory

## Requirements

- A terminal with true color (24-bit) support (e.g., Ghostty, iTerm2, Kitty, WezTerm)
- A [Nerd Font](https://www.nerdfonts.com/) installed and configured in your terminal
- `jq` installed (`brew install jq` on macOS)
- `git` (for branch detection)

## Install

### Quick install

```bash
curl -fsSL https://raw.githubusercontent.com/TheDokT0r/claude-code-statusline/master/install.sh | bash
```

This downloads the script to `~/.claude/statusline-command.sh` and configures `~/.claude/settings.json` automatically.

### Manual install

1. Copy the script somewhere permanent:

```bash
cp statusline.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

2. Configure Claude Code to use it. Add to your `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

3. Restart Claude Code.

## Customization

### Colors

Each segment has an RGB color defined as a space-separated string. Edit the `R_*` variables to change them:

```bash
R_MODEL="180 60 100"    # rose
R_FOLDER="190 110 40"   # orange
R_BRANCH="175 150 30"   # gold
R_CHANGES="40 135 160"  # teal
R_TOKENS="60 100 170"   # blue
R_UPTIME="130 60 150"   # purple
R_COST="105 55 165"     # violet
```

### Terminal background

Set `R_TERM` to match your terminal's background color for clean gradient edges:

```bash
R_TERM="28 28 28"  # Ghostty default
```

## How it works

Claude Code pipes a JSON object to the statusline command via stdin. The script parses it with `jq` and builds ANSI-colored output. The JSON includes:

| Field | Description |
|-------|-------------|
| `model.display_name` | Current model name |
| `workspace.current_dir` | Working directory |
| `context_window.used_percentage` | Context usage % |
| `context_window.total_input_tokens` | Total input tokens |
| `context_window.total_output_tokens` | Total output tokens |
| `cost.total_cost_usd` | Session cost in USD |
| `cost.total_duration_ms` | Session duration |
| `cost.total_lines_added` | Lines added |
| `cost.total_lines_removed` | Lines removed |

## License

MIT
