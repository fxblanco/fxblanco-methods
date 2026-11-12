---
name: lessons
description: >
  Lessons learned, two modes. EXTRACT: pull lessons from the current
  conversation (mistake + fix, discarded approaches, gotchas) and store them
  as notes in the knowledge store. Triggers: "save lessons", "lesson
  learned", "/lessons", "what did I learn" (German: "lessons speichern", "was
  hab ich gelernt", "merk dir die lesson"), or before "commit and push".
  QUERY: before answering a question about deploys, migrations, integrations
  or platform quirks, check the knowledge index for 1–3 matching lessons.
---

# Lessons Learned

Lessons are condensed insights from real mistakes and real fixes. They live
in the knowledge store, so every project can use them. Behavior rules for the
assistant belong in memory (`learn`), not here.

## Mode 1: EXTRACT

### What counts
- Mistake + fix: "X failed because Y, the fix was Z".
- Discarded approaches and why they failed.
- Third-party gotchas: undocumented behavior, silent failures.
- Process insights: "check X before Y next time".

Skip routine work, one-off bugs without a general rule, and anything already
stored.

### Where
- One topic area → `<knowledge_path_pattern>/lessons/YYYY-MM-DD-<slug>.md`
- Cross-cutting (AI workflow, deploy, tooling) → the cross-cutting lessons
  directory.

Create directories when you first write to them.

### Format

```yaml
---
title: <one clear sentence>
type: lesson
areas: [<area>]
project: <slug, optional>
tags: [<same taxonomy as the knowledge store>]
date: YYYY-MM-DD
status: active
source: <session or ticket>
related: [<relative links, optional>]
---
```

```markdown
## What happened
<1–3 sentences>

## Rule
<the general rule, clear enough to understand in 6 months>

## Why
<root cause, so the rule is not read as dogma>

## How to apply
<trigger condition or checklist item>
```

Good example: "Theme CSS beats component CSS via load order, not
specificity", with a rule (use explicit values inside themes) and a check
(computed styles in DevTools). Bad example: "Selector was wrong, fixed it."
That has no general rule, so do not save it.

### Flow
1. Find lesson signals and group them: one lesson per insight.
2. For 1–2 lessons, save them and say so. For more than 3, list them and ask
   first.
3. Write one file per lesson.
4. Run the consumer's `indexer_command`, if configured.
5. If the lesson has `project:` and a matching project memory file exists,
   add a line under `## Lessons` there:
   `- [<title>](<relative path>) — <one line>`.
6. Report the paths.

## Mode 2: QUERY

Use it when a question touches a topic with stored lessons, for example
deploys, migrations, browser automation or a third-party integration. Skip it
for small talk and simple lookups.

1. Read the knowledge index once.
2. Filter `type: lesson` by tag and project match.
3. Load the top 1–3 files.
4. Answer with a short pointer: "Lesson from <date>: <core point>".

No match: answer normally and do not mention the search.
