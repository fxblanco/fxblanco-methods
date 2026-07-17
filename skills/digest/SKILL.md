---
name: digest
description: >
  Inbox processor — scans the inbox and per-area raw layers, classifies,
  distributes, and calls research when a deep dive is warranted. Use when
  the user says "digest", "process the inbox", "clean up the inbox", "what
  bookmarks are pending", "empty the inbox" (German equally: "digest inbox",
  "verarbeite inbox", "inbox aufräumen", "leer die inbox"). Also callable
  from maintenance routines in silent mode (move + classify only, no
  research call).
---

# Digest

Processes the inbox + per-area raw layers. All paths derive from the
pipeline storage contract (`skills/storage-contract.md` in the methods repo)
and the consumer's `.methodik-capabilities.json`.

- Classifies every input by type + topic area
- Moves inbox items into the right area's raw layer
- Calls the `research` skill when a deep dive is warranted
- Proposes knowledge-layer compression when ≥3 related raws sit in one area

**Core principle:** `capture` fills raw, `digest` sorts, `research` condenses.

## Silent mode — for scheduled runs

If called with `--silent`:

- Scan the inbox + per-area raw folders
- Per file: read frontmatter + content, classify the topic area
- **If the area is unambiguous:** `git mv <inbox>/<file> <area raw>/<file>`
  + frontmatter update
- **If the area is unclear or ambiguous:** leave it in the inbox — **never guess**
- **No research call.** Deep dives are exclusively user-triggered
- No cluster proposals in silent mode
- Short commit if anything moved:
  ```bash
  cd <consumer repo root>
  if ! git diff --cached --quiet; then
    git add -A && git commit -m "chore(digest): silent run $(date +%Y-%m-%d) — N items sorted"
  fi
  ```

Silent-mode output: **one log line** (`digest silent: 3 moved, 2 stayed in
inbox`). No chat output.

---

## Full mode — interactive or on demand

Everything below applies to the full run. Stop here on `--silent`.

### Phase 1: Scan

Find all markdown files in the inbox + raw layers that are newer than the
index, plus files without frontmatter or with `status: draft`.

### Phase 2: Classification per file

For each file found:

1. **Read frontmatter** (title, source, tags)
2. **Scan content** (first ~500 words)
3. **Detect type:**
   - video URL / video transcript → `type: research-candidate`
   - social media post → `type: bookmark`
   - article / blog → `type: bookmark`
   - screenshot / image → `type: visual`
   - own note → `type: note`
4. **Classify the topic area:**
   - if `areas:` is set in frontmatter → use it directly (no guessing)
   - if `areas:` is empty → keyword match against the knowledge index's tag
     taxonomy
   - ambiguous → put the item into the DECIDE block with a suggestion
5. **Suggest an action:**
   - `auto-move` — area unambiguous, just move
   - `research-condense` — call the `research` skill (long content, videos)
   - `manual-classify` — the user must confirm the area
   - `delete` — obvious junk (only if the user confirms)

### Phase 3: DECIDE block

```
━━━ DIGEST [date] ━━━

Inbox: N items (M in inbox, K in area raws)

1/N [video] <title> — <source> (inbox)
    ⎯ <1-sentence extract from content>
    Suggestion: call research → <area knowledge layer>/<slug>.md
    [y=research / e=different area / s=skip / d=delete]

2/N [bookmark] <title> — <source> (inbox)
    ⎯ <1-sentence extract>
    Suggestion: move → <area raw>/<slug>.md
    [y=move / e=different area / s=skip]

3/N [note] <title> — (<area>/raw)
    ⎯ <1-sentence extract>
    No move needed. 3+ related files on "<topic>" — propose compression?
    [y=condense / s=skip]
```

### Phase 4: Execution (after approval)

Per item:

**`y=move`:**
```bash
git mv <inbox>/<file>.md <area raw>/<file>.md
# frontmatter update: areas=[<area>], status=active
```

**`y=research`:**
- call the `research` skill with the file as input
- output lands in the area's knowledge layer
- the original raw file stays (for verification)

**`y=condense`:**
- call the `research` skill in aggregation mode (several raws → one
  knowledge note)
- propose to the user: "3 files on '<topic>' → one condensed note?"

**`d=delete`:**
- `git rm <inbox>/<file>.md` (only with explicit approval)

### Phase 5: Update the index

At the end, automatically run the consumer's `indexer_command` (if
configured). Commit: `chore(digest): N items processed YYYY-MM-DD`

## Cluster detection

Per area after migration: check whether ≥3 raws share tag overlap. If so,
propose compressing them into one knowledge-layer note (via `research` in
aggregation mode).

## Anti-patterns

- Never delete inbox files without approval
- Never call `research` on files under ~200 words (wastes tokens)
- Always run the indexer at the end (skill chain with `wiki-maintain`)

## Integration with maintenance routines

When a daily maintenance routine runs and the inbox has >0 files:

```
Inbox: 3 unprocessed items — digest? (y/n)
```

On `y` → activate the digest skill and queue the DECIDE block.
