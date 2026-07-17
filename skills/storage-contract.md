# Pipeline storage contract (capture → digest → research)

Host-neutral contract for where pipeline content lands. **No path in the
three pipeline skills is hardcoded** — every target derives from the
consumer's `.methodik-capabilities.json`. In a submodule consumer this file
is readable at `.vendor/fxblanco-methods/skills/storage-contract.md`.

## Roles (per `methods/pkm.md`)

| Role | What lives there | Written by |
|---|---|---|
| **Inbox** | captures whose topic area is unclear — parked, not lost | `capture` |
| **Raw layer** (per area) | unprocessed captures with a known area: notes, bookmarks, transcripts, images | `capture`, `digest` (moves), `research` (source dumps) |
| **Knowledge layer** (per area) | condensed, cross-linked notes — the reusable knowledge | `research` (and lessons/wiki skills) |
| **Index** | machine-generated router over the whole store | the consumer's indexer (`indexer_command`) |

## Path derivation

From the capability file:

- **`storage_path_pattern`** (required for pipeline consumers) — the raw
  layer, with a `<domain>` placeholder. Example: `knowledge/<domain>/raw/`.
  The raw path for area `x` = the pattern with `<domain>` → `x`.
- **`inbox_path`** (optional) — where unclassified captures land.
  Default if absent: `storage_path_pattern` with `<domain>` → `_inbox`,
  with any trailing `raw/` segment dropped.
- **`knowledge_path_pattern`** (optional) — the condensed layer, with a
  `<domain>` placeholder. Default if absent: `storage_path_pattern` with its
  trailing `raw/` segment replaced by `wiki/`. If the consumer's raw pattern
  does not end in `raw/`, this field MUST be set explicitly.
- **`indexer_command`** (optional) — run after structural changes so the
  index never drifts (see `methods/pkm.md`).

## File contract

Every file written into inbox or raw gets minimal frontmatter (the indexer
depends on it):

```yaml
---
title: <short>
type: raw            # or: wiki once condensed
areas: [<area>]      # empty if unclear (inbox)
tags: [<inferred>]
date: YYYY-MM-DD
status: draft        # until digest/research processes it
source: <url if any>
---
```

Filename: `<YYYY-MM-DD>-<3-4-word-slug>.md`. Multi-file sources (e.g.
transcripts) get a subfolder in the raw layer: `<raw>/<slug>/`.

## Division of responsibility (hard boundaries)

- **`capture` only stores.** Never processes, never moves existing inbox
  items, never writes to the knowledge layer.
- **`digest` only sorts.** Classifies inbox/raw items, moves them to the
  right raw layer, flags candidates — never condenses content itself.
- **`research` only condenses.** Turns sources into knowledge-layer notes;
  keeps the raw sources it worked from.
- Nobody deletes without explicit user approval.
