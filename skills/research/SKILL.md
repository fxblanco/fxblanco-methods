---
name: research
description: >
  Research one or more YouTube videos, web URLs, PDFs, or a topic: fetch the
  content, store it as a structured knowledge note with cross-links, and
  re-run the indexer. Triggers: "look at this video: <url>", "what's he
  saying: <url>", URL drop-in, "research X", "videos on X" (German equally:
  "recherchier X", "mach mir Research zu Z").
---

# Research

Turns videos, web pages, PDFs and topics into **knowledge notes** in the
right topic area. Paths come from the consumer's `.methodik-capabilities.json`
(`storage_path_pattern`, `knowledge_path_pattern`, `indexer_command`).

- Note → `<knowledge_path_pattern>/<slug>.md`
- Raw data (transcripts, metadata, sources) → `<storage_path_pattern>/<slug>/`
- No matching area → use the area `research`.

Keep the raw files. Follow-up questions often need the full source.

## Flow

### 1. Detect the input
- **YouTube** (`youtube.com/watch`, `youtu.be/`, `youtube.com/shorts/`) → step 2.
- **Web URL** → fetch the page and analyze it directly.
- **PDF** → download it and read it with the document tool.
- **Topic only** → web search, optionally `yt-dlp ytsearch3:"<topic>"`.

If the purpose is unclear, ask once ("what do you want to use this for?").
Then act.

### 2. Fetch the transcript (YouTube)
If the consumer has its own video script (for example
`scripts/video-learn/run.mjs`), use it. Otherwise:

```bash
yt-dlp --skip-download --write-auto-sub --write-sub \
  --sub-lang "en.*,de.*" --convert-subs vtt --write-info-json "<url>"
awk '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9]/{next} /^WEBVTT/{next} /^Kind:/{next} /^Language:/{next} /^$/{next} {gsub(/<[^>]*>/,"")} {print}' file.vtt | awk '!seen[$0]++' > file.txt
```

On `HTTP Error 429`: get title and description with
`yt-dlp --print "%(title)s" --print "%(description)s" --no-download "<url>"`
and add a web search. Write in the note: "Transcript via 429 fallback, not a
full transcript."

### 3. Analyze and route
- Read the full content and the knowledge index.
- Pick the area by tag match. Content for several areas → `areas: [<a>, <b>]`.
- If two areas fit equally, ask for the primary one.
- If the source is unclear, write "unclear from the source". Do not invent
  takeaways.

### 4. Write the note

```yaml
---
title: <plain-text title>
type: wiki
areas: [<area1>, <area2>]
project: <optional>
tags: [<topic1>, <topic2>]
date: YYYY-MM-DD
status: active
source_type: video | web | pdf | topic
sources: [https://...]
related: [<relative path to related note>]
---
```

The frontmatter is required, because the indexer only finds notes with it.
Set `related:` whenever a project connection exists.

Body:
- `## Why this is here`: 1–3 sentences on the use case.
- `## TL;DR`: 3 bullets.
- `## Key insights`: one subsection per source, with timestamps where possible.
- `## Contradictions`: only with several sources.
- `## Action items`: only if there is a concrete project.

### 5. Link and index
- In each area entry-point doc from `areas:`, add a line under
  `## Research references`:
  `- **[<short title>](<relative path>)** (<date>): <1–2 sentences>`
- Run the consumer's `indexer_command`.

### 6. Report
Give the path. Offer the content as 5 readable bullets in chat.
