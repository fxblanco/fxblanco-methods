# Skills

Each skill lives here as its own directory (`<name>/SKILL.md` + any assets), with a matching entry in `../manifest.json` declaring `target_type` (`skill` / `command` / `command+skill`) and `surfaces` (which runtime(s) it's compatible with — the Codex-family planning skills are Claude-only, since they orchestrate `codex exec` and don't make sense exposed as a Codex-side skill). The capture/digest/research pipeline shares the storage contract in [`storage-contract.md`](./storage-contract.md).

Content is runtime-neutral: identical bytes materialize into both `.claude/skills/<name>/` and `.agents/skills/<name>/` in a consumer repo. Anything host-specific (paths, memory location, how parallel work gets launched) is read at runtime from the consumer's `.methodik-capabilities.json`, not baked in here.

Landed (each passed a content safety pass — no client names, no secrets, no personal specifics beyond what's generic): `council`, `lessons`, `learn`, `wiki-maintain`, the `capture`→`digest`→`research` pipeline, `kickstart-assistant`'s portable core, and the Codex family (`grill-me-codex`, `grill-with-docs-codex`, `codex-build`, `codex-review`).
