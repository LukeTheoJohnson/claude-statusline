# Roadmap

The guiding principle: a status line earns its width by turning data into
**decisions**, not by showing more fields. The pacing marker answers "am I going
too fast?" instead of printing a number — every item here is held to that bar.

Field names below are verified against the
[Claude Code status line docs](https://code.claude.com/docs/en/statusline).

## Done

- Single `node` process per render (git resolved in-process, no second spawn).
- Weekly (`rate_limits.seven_day`) limit segment with pacing marker + reset.
- Actual context window: uses `context_window.context_window_size` and token
  counts, so it reads correctly on 200k **and** 1M-context models.
- `refreshInterval` documented so time-based segments stay live while idle.

## Tier 1 — headline differentiators

These need a small per-render state cache (append `pct,timestamp` to
`$TMPDIR/cc-sl-$session_id`). That's the step up from the current stateless
design — and it's where the uniqueness lives, because almost no status line
shows *trajectory* or *time-to-compact*.

- **Predictive auto-compact ETA** — `ctx:72% ≈4 msgs`. Project messages until
  compaction from the context growth rate.
- **Context trajectory sparkline** — `ctx:72% ▁▂▃▅▇`. A short trend so you see
  the rate, not just the snapshot.

## Tier 2 — high-value, stateless

- **Binding-limit highlight** — when both 5h and weekly are shown, emphasise
  whichever is the tighter ceiling.
- **Cost burn rate** — `$1.34 ($6/hr)` from `total_cost_usd / total_duration_ms`.
- **Absolute tokens free** — optionally surface `Nk` remaining from
  `context_window_size − total_input_tokens`. Dropped from the default render as
  redundant with the `ctx:%` figure; revisit only if the raw count earns its width.
- **Session name / worktree** — `session_name` and `workspace.git_worktree` when
  present; silent otherwise. Payoff for multi-session, multi-worktree work.

## Tier 3 — adoption & robustness

- **Config block** — choose segments/order/thresholds via env vars or a
  top-of-file object, so others adopt without editing the render code.
- **Sample payloads + `demo.sh`** — render offline for contributors and tests.
- **Graceful degradation** — detect missing `node`, print a minimal fallback
  instead of a blank bar.

## Explicitly not doing

`vim.mode`, `output_style.name`, `thinking.enabled`, `agent.name` — real fields,
but clutter that dilutes the signal. Add only on demand.
