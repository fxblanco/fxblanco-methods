# fxblanco-methods

Felix Blanco's personal working methodology — how ideas turn into shipped work, independent of which repo or which AI runtime (Claude Code, Codex CLI) is doing the work.

## What lives here

- `core/METHOD.md` — the one universal law: evidence-first, always cite a source, say "I don't know" instead of guessing.
- `methods/` — named principles (token discipline, PKM, autonomy/doing-mode, retrieval), each with an explicit applicability note.
- `personal-profile/` — Felix-specific working rules (priorities, working hours). Imported explicitly by consumers that want it — not bundled into `core`.
- `skills/<name>/` — runtime-neutral skill packages (Claude Code + Codex CLI both read the same content; host-specific bits come from a `.methodik-capabilities.json` the consumer provides, read at runtime — not baked in here).
- `scripts/sync-consumer.sh` — the single canonical script that materializes skills into a consumer repo's `.claude/skills/` and `.agents/skills/`.
- `manifest.json` — skill inventory, content hashes, per-artifact `target_type` + `surfaces`.

## How it's consumed

Each consumer repo (currently: [second-brain](https://github.com/fxblanco) — private) adds this repo as a git submodule under `.vendor/fxblanco-methods`, provides its own `.methodik-capabilities.json`, and runs `scripts/sync-consumer.sh`. Pin is bumped deliberately (~every 2 weeks), never live-synced.

The Codex-family skills (`grill-me-codex`, `grill-with-docs-codex`, `codex-build`, `codex-review` — Claude-orchestrated adversarial planning workflow) are additionally installed globally via a pinned, tagged checkout — see `skills/README.md`.

## Origin

Grew out of second-brain, Felix's private knowledge/state repo — see `docs/adr/` for the split decisions as they accumulate. Some of the grilling/review workflow is adapted from [mattpocock/skills](https://github.com/mattpocock/skills) (MIT) — see `THIRD-PARTY-NOTICES.md`.

## Status

Early — under active construction, structure may still shift.
