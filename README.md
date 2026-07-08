# claude-statusline

A single-file status line for Claude CLI using the JSON pipes to stdin. No dependencies beyond `bash` and `node`.

![screenshot](assets/statusline.png)

## Design notes

- **information is relevant** Segments drop out when they have no value. Each piece of dispalyed info has direct impact on the next prompt. 
- **No external HUD.** Renders from one payload. Nothing to install
- **Half a screen, at most.** The line is kept deliberately narrow so it stays fully readable in split-pane terminals — running several panes side by side (Windows Terminal `Ctrl+Shift+D`, tmux splits) shouldn't truncate it. Segments earn their width or drop out; that's why the raw token count went.
- **Colour coding** the traffic light thresholds on context and rate limits are readable. Main is red to avoid direct commits. 

## Details

| Segment | Meaning |
| --- | --- |
| `main` / `feature-x` | Current git branch. **Red on `main`/`master`** as a commit guard. |
| `Opus 4.8` | Active model (`display_name`, straight from the payload). |
| `E:high` | Reasoning effort level. |
| `+120/-34` | Lines added / removed this session (keep grounded with code changes). |
| `$0.42` | Session cost in USD (estimated based on api pricing). |
| `ctx:38%░░` | Context-window usage + mini bar (percentage is relative to the real `context_window_size`, so it reads right on 200k and 1M models). Green under 15%, amber under 50%, red beyond. |
| `⚠200k` | Flag when the session exceeds the 200k-token window (Does not adjust). |
| `5h:61%▓▓│░→2h14m` | Five-hour rate-limit usage, a pacing marker, and time until reset. |
| `7d:41%▓░│░→2d23h` | Seven-day (weekly) rate-limit usage — often the binding limit on Max plans — pacing marker and reset. |

## Requirements

- `bash`
- `node` on your `PATH`

## Install

1. Copy `statusline-command.sh` to `~/.claude/statusline-command.sh`.
2. Point Claude Code at it in `~/.claude/settings.json`:

   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash ~/.claude/statusline-command.sh",
       "refreshInterval": 10
     }
   }
   ```

   `refreshInterval` (seconds) re-runs the script on a timer as well as on events — without it the reset countdowns freeze while the session sits idle.

3. Restart Claude Code (or start a new session).

### Windows

Claude Code runs the command through `bash` (Git Bash / WSL). `~` isn't always expanded, so use an absolute path with forward slashes:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash C:/Users/YOU/.claude/statusline-command.sh",
    "refreshInterval": 10
  }
}
```

## Customising

The whole thing is one readable script. To change what shows or the order, edit the `parts.push(...)` calls in `statusline-command.sh` — each segment is a couple of lines. ANSI colour codes are the `"0;3x"` strings passed to `c(...)`.

## Licence

MIT — see [LICENSE](LICENSE).
