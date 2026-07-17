---
name: research
description: >
  Research a YouTube video (or several), a web URL, or a topic: fetch the
  transcript/content, enrich it with knowledge-store context, store it as a
  structured note in the knowledge layer, and set cross-links via
  frontmatter. Two modes: Mode A (quick, BUILT) = analyze one or more
  concrete videos/URLs. Mode B (deep, NOT YET IMPLEMENTED) = external
  deep-research service with an audio deliverable — say so honestly if
  triggered. Triggers: "look at this video: <url>", "what's he saying:
  <url>", URL drop-in, "research X", "do research on Y", "videos on X"
  (German equally: "recherchier X", "mach mir Research zu Z").
---

# Research

Turns YouTube videos, web pages, and topics into structured **knowledge
notes**, linked into the right topic areas. All paths derive from the
pipeline storage contract (`skills/storage-contract.md` in the methods repo)
and the consumer's `.methodik-capabilities.json`.

## Output paths

- Condensed research note → the area's knowledge layer:
  `<knowledge_path_pattern with domain>/<slug>.md`
- Raw data (transcripts, sources) → the area's raw layer, in a subfolder:
  `<storage_path_pattern with domain>/<slug>/`
- Cross-cutting research that has no area yet → a reserved `research` area
  (same patterns, `<domain>` → `research`)

The area is declared via frontmatter `areas: [<a>, <b>]` — the cross-area
lever.

## Modes

### Mode A — quick (one or more videos/URLs, no external service)
Default on URL drop. Fast, ~2 min, no external service needed.

### Mode B — deep (topic research via an external notebook/deep-research service)
Trigger phrases: "research X", "do me research on Y", "I want more on this".
**Status: not yet implemented** — if the user triggers Mode B, say: "Mode B
(deep research) isn't built yet. Want me to set it up now?"

---

## Mode A — flow

### 1. Collect URL(s), detect type, clarify

**URL type detection (before any transcript fetch):**
- **YouTube** (`youtube.com/watch`, `youtu.be/`, `youtube.com/shorts/`) →
  continue with step 2 (yt-dlp)
- **Web URL** (other HTTP/HTTPS) → web fetch/search; no yt-dlp. Analyze the
  content directly.
- **PDF URL** (`.pdf` in the URL or `Content-Type: application/pdf`) →
  download the PDF and analyze it with the host's document reading tool.
- **No URL, just a topic** → web search on the topic + optionally a YouTube
  search via yt-dlp (`yt-dlp ytsearch3:"<topic>"`)

If it's unclear why / what for: **ask once, briefly** ("what do you want to
use this for?"). Not more.

### 2. Fetch transcripts with yt-dlp (YouTube only)

```bash
mkdir -p <scratch>/research-<video-id>
cd <scratch>/research-<video-id>
yt-dlp --skip-download --write-auto-sub --write-sub \
  --sub-lang "en.*,de.*" --convert-subs vtt \
  --write-info-json "<url>"
```
- yt-dlp must be installed; if not → install it.
- Clean VTT to text (strip timestamps + duplicates):
```bash
awk '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/{next} /^WEBVTT/{next} /^Kind:/{next} /^Language:/{next} /^$/{next} /<c>/{gsub(/<[^>]*>/,"")} {print}' file.vtt | awk '!seen[$0]++' > file.txt
```

**Fallback on HTTP 429 (YouTube rate limit on the subtitle endpoint):**
if `--write-auto-sub` fails with `ERROR: HTTP Error 429: Too Many Requests`:
```bash
yt-dlp --print "%(title)s" --print "%(description)s" --no-download "<url>"
```
For many videos (shorts, news, tutorials) the description already carries the
key points. Combine the metadata output with a web search on the video's
topic as a transcript substitute. Note in the knowledge note: "Transcript via
429 fallback (metadata + web search) — not a full transcript."

### 3. Read & analyze transcripts
- Title from the filename or info.json
- Read the complete transcripts
- **Load the knowledge index** — for cross-area context
- Read the relevant area entry-point docs + existing knowledge-layer files
  with matching tags

### 4. Topic routing
- Match against the consumer's topic areas via the index's tags
- Multi-area content → `areas: [<a>, <b>]` in frontmatter
- Ambiguous → **ask the user** ("This fits both <a> and <b> — primary area?")
- Clear → propose and proceed

### 5. Create the raw folder & store transcripts
```
<area raw>/<slug>/
  transcript-XX-*.txt     # cleaned text
  info-XX-*.json          # yt-dlp metadata
  sources.md              # URLs, creator
```

### 6. Create the knowledge note
Path: `<area knowledge layer>/<slug>.md` (flat, single file).
Slug: short, kebab-case, self-explanatory.

### 7. Frontmatter (mandatory)

```yaml
---
title: <plain-text title>
type: wiki
areas: [<area1>, <area2>]    # the cross-area lever
project: <optional>
tags: [<topic1>, <topic2>]    # relevance for cross-queries
date: YYYY-MM-DD
status: active
source_type: video
sources:
  - https://...
related:
  - <relative path to related note in another area>
---
```

### 8. Body structure

```markdown
# <Title>

## Why this is here
<1-3 sentences: what did the user see, what do they want it for, what's the
concrete use case>

## TL;DR (3 bullets)
- <3 crisp core takeaways>

## Key insights
### Video 1 — <title> (<id>)
- <insights, with timestamps where possible>

### Video 2 — <title> (<id>)
- ...

## Contradictions / tensions
<with multiple sources: where do they disagree>

## Cross-links
<links to related files via relative paths>

## Action items for <project>
### Quick wins
- [ ] ...
### Next session
- [ ] ...
### Open / to verify
- [ ] ...
```

### 9. Cross-links into existing files
In each area entry-point doc listed in the note's `areas:` frontmatter:
- add a `## Research references` section (at the end, if not present)
- entry:
```markdown
- **[<short title>](<relative path to the note>)** (<date>) — <1-2 sentences on what's inside>
```

### 10. Re-run the indexer
Run the consumer's `indexer_command` so the new note appears in the
cross-area index.

### 11. Two-presentation output in chat
After storing, **always** ask whether the user wants the readable version:
> "Done. Want the content again here in chat, in 5 readable bullets?"

Because: markdown files are for lookup, chat output is for immediate
understanding.

---

## Integration with digest

When `digest` finds a research candidate (a URL in the inbox, long video
transcripts, video bookmarks), it calls `research` with that file as input.
Output: a knowledge note in the right area.

---

## Rules

- **Always cross-link** when there's a project connection (via `related:` in
  frontmatter). Otherwise the research is never found again.
- **Keep transcripts**, don't delete them. The raw source is valuable for
  follow-ups. Always in the raw subfolder.
- **Never invent TL;DRs** — if the transcript is unclear, write "unclear
  from the video" instead of hallucinating.
- **Ask once, then act.** No endless clarification loops.
- **External deep-research services are optional.** Most research flows
  don't need them.
- **Frontmatter is mandatory** — otherwise the note never shows up in the
  knowledge index.
- **Run the indexer at the end** (don't forget, or cross-area queries go
  stale).
