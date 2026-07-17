---
name: capture
description: >
  Quick capture — store a quick note, photo, dictation, or bookmark. Use when
  the user says "capture: X", "/capture", "note this down", "save that link",
  "into the inbox", "here's something" (German equally: "wegspeichern",
  "notier mal", "capture das", "ab in die inbox", "speicher den Link"), or
  drops a photo/screenshot/voice note/URL without immediate context. If the
  topic area is clear, write straight into that area's raw layer; otherwise
  into the inbox.
---

# Capture

Writes any quick input (note, link, photo, dictation) to the right place in
the knowledge store. **No processing — storage only.** Processing is
`digest`'s job. All paths derive from the pipeline storage contract
(`skills/storage-contract.md` in the methods repo) and the consumer's
`.methodik-capabilities.json`.

## Target folders

| Input | Target |
|-------|--------|
| Topic area **clear** (the user names it) | that area's raw layer: `<storage_path_pattern with domain>/<date>-<slug>.md` |
| Topic area **unclear** or ambiguous | inbox: `<inbox_path>/<date>-<slug>.md` |
| Bookmark without context | inbox |

## Frontmatter standard

Every capture gets minimal frontmatter (contract-mandated — omitting it
blinds the indexer):

```yaml
---
title: <short>
type: raw
areas: [<area>]          # empty if unclear
tags: [<inferred>]        # guessed from content
date: YYYY-MM-DD
status: draft             # until digest/research condenses it
source: <url if any>
---
```

## Input types

### 1. Short note / dictation
- Take the text over; for dictation, smooth out sentence fragments
- Filename: `<date>-<3-4-word-slug>.md`

### 2. URL / bookmark
- Get the title from the URL (if possible) or user-provided
- Set `source:` in frontmatter
- Body: the user's note + the URL

### 3. Photo / screenshot
- Store the image in the raw folder
- Markdown file next to it with the image reference
- OCR if handwriting/whiteboard is recognizable
- If text is illegible: ask

### 4. Triaging existing inbox items
- If the user asks "what's in the inbox?" → show the list
- Per item: type, age, suggested action (digest, research, delete)
- **Don't process them yourself** — that's `digest`'s job

## Flow

1. The user provides input (text, URL, image, voice note)
2. If unclear, ask once: which area? (be specific if two are plausible)
3. Clear area: write directly into that area's raw layer
4. Unclear area: write into the inbox
5. Short confirmation: `Captured: <path>`
6. If ≥3 unprocessed items sit in the inbox → suggest a digest run

## Output format

```
Captured: <path>
  Title: <short>
  Tags: <inferred>
  [3 unprocessed items in inbox — run digest? (y/n)]
```

## Not for

- Tasks with deadlines → the consumer's task system, not the inbox
- Structured notes that need analysis → the `research` skill
- Anything with its own dedicated ingestion flow in the consumer

## Anti-patterns

- Never write directly into the knowledge layer — it holds condensed
  content. Raw comes first.
- Never move inbox files automatically — that's digest's job.
- Never omit frontmatter — it blinds the indexer.
