# Roadmap

The guiding principle: a status line earns its width by turning data into
**decisions**, not by showing more fields. The pacing marker answers "am I going
too fast?" instead of printing a number — every item here is held to that bar.

A second rule, learned the hard way: **never replicate what Claude Code already
shows natively.** The session name lives in the banner above the chat; the PR
lives in the built-in footer badge (the `pr.*` payload literally "mirrors" it).
A segment only earns its place by giving persistence the native UI doesn't. See
*Explicitly not doing*.

Field names below are verified against the
[Claude Code status line docs](https://code.claude.com/docs/en/statusline).

## Done

- Single `node` process per render (git resolved in-process, no second spawn).
- Weekly (`rate_limits.seven_day`) limit segment with pacing marker + reset.
- Actual context window: uses `context_window.context_window_size` and token
  counts, so it reads correctly on 200k **and** 1M-context models.
- `refreshInterval` documented so time-based segments stay live while idle.
- Worktree identity (`workspace.git_worktree`): grey `wt:` frame, silent unless
  you're in a linked worktree. Colour stays reserved for decisions. (PR status
  and session name were tried and dropped — both duplicate native Claude Code
  UI; see *Explicitly not doing*.)
- Plan-aware `$`: the session-cost figure shows only on pay-go (API/Console). On
  a Pro/Max subscription — detected by `rate_limits` being present — dollars are
  a phantom pay-go estimate, so they're hidden and the quota segments carry
  "spend" instead.

## Tier 1 — headline differentiators

These need a `session_id`-keyed state cache (`$TMPDIR/cc-sl-$session_id.json`)
holding a short `pct,timestamp` history — which is where the uniqueness lives:
almost no status line shows *trajectory* or *time-to-compact*.

- **Predictive auto-compact ETA** — `ctx:72% ≈4 msgs`. Project messages until
  compaction from the context growth rate.
- **Context trajectory sparkline** — `ctx:72% ▁▂▃▅▇`. A short trend so you see
  the rate, not just the snapshot.

## Tier 2 — high-value, stateless

- **Binding-limit highlight** — when both 5h and weekly are shown, emphasise
  whichever is the tighter ceiling.
- **Absolute tokens free** — optionally surface `Nk` remaining from
  `context_window_size − total_input_tokens`. Dropped from the default render as
  redundant with the `ctx:%` figure; revisit only if the raw count earns its width.

## Tier 3 — adoption & robustness

- **Config block** — choose segments/order/thresholds via env vars or a
  top-of-file object, so others adopt without editing the render code.
- **Sample payloads + `demo.sh`** — render offline for contributors and tests.
- **Graceful degradation** — detect missing `node`, print a minimal fallback
  instead of a blank bar.

## Explicitly not doing

**Don't replicate what Claude Code already shows natively** — the statusline
earns its width on *persistent* signals the built-in UI doesn't keep on screen.
Casualties of this rule:

- `session_name` — already shown in the banner above the chat.
- `pr.*` — the docs say the payload "mirrors the PR badge in the bottom status
  bar," so rendering it here just double-prints the native footer badge.

**Burn rate in dollars** — `total_cost_usd` is a pay-go *estimate*; on a
subscription (flat fee) it's a phantom, so a `$/hr` figure misleads exactly the
users who have `rate_limits`. Dropped in favour of the raw quota segments, which
show the thing that's actually finite on a plan.

**Session quota-burn** (`5h:14% +8%`) — a `session_id`-keyed baseline in tmp
meant to show how much of the 5h window *this* session had eaten. Shipped, then
removed: the per-session delta didn't track reliably (the baseline anchors to
first render, not session start, and drifts across concurrent sessions and
window rebaselines). The raw `5h:%` segment and `/usage` already carry the
signal without the false precision.

`vim.mode`, `output_style.name`, `thinking.enabled`, `agent.name` — real fields,
but clutter that dilutes the signal. Add only on demand.
