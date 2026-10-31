# claude-statusline

A simple and effective status line for Claude CLI. It uses the JSON pipes to stdin and has no dependencies beyond `bash` and `node`.

![screenshot](assets/statusline.png)

## Design notes

- **information must be relevant:** Each piece of displayed info has direct impact on the next prompt. 
- **No extra bloat:** Renders from one payload. Nothing to install
- **Half screen width considered:** The line is kept deliberately short so it stays readable in split pane terminals. Running several panes side by side (Windows Terminal `Ctrl+Shift+D`, tmux splits) shouldn't lose info.
- **Density->Clarity:** Segments are encoded in the fewest characters that stay unambiguous. e.g `label:value`, glyphs and arrows over words (`→2h14m`, not "resets in 2h 14m").  Density serves clarity
- **Colour coding:** Text colour carries meaning as well. The traffic light thresholds on context and rate limits are readable. Main branch is red.

## Details

| Segment | Meaning |
| --- | --- |
| `main` / `feature-x` | Current git branch. **Red on `main`/`master`** as a commit guard. |
| `Opus 4.8` | Active model (`display_name`, straight from the payload). |
| `E:high` | Reasoning effort level. |
| `+120/-34` | Lines added / removed this session (keep grounded with code changes). |
| `$0.42` | Session cost in USD (estimated based on api pricing). |
| `ctx:38%░░` | Context-window usage + mini bar (percentage is relative to the real `context_window_size`, so it reads right on 200k and 1M models). Green under 15%, amber under 50%, red beyond. |
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

3. Restart Claude Code.

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

## Licence

MIT — see [LICENSE](LICENSE).
