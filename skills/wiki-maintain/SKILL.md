---
name: wiki-maintain
description: >
  Knowledge-store maintenance: regenerate the index, find dead links, detect
  frontmatter drift and tag drift, propose clusters for compression. Use when
  the user says "wiki-maintain", "update the index", "check dead links",
  "clean up the wiki", "/wiki-maintain" (German equally: "index updaten",
  "dead links prüfen", "wiki aufräumen"). Also callable from a daily
  maintenance routine (silent mode — indexer only) and a weekly one
  (deep: dead links, clusters, drift).
---

# Wiki-Maintain

Keeps the consumer's knowledge index current and checks the health of the
knowledge store (structure per `methods/pkm.md`). The concrete indexer is the
consumer's own — its invocation comes from `indexer_command` in
`.methodik-capabilities.json`. If the consumer also maintains a derived
knowledge graph, its builder runs alongside the indexer; the method below
treats it as optional.

## Silent mode — for a daily maintenance routine

If called with `--silent` or `--index-only`:

- Run the consumer's `indexer_command`.
- Run the graph builder too, if the consumer has one (it should be
  idempotent + deterministic; if an external data source is unavailable it
  should build what it can and continue — no crash, just a note in the output).

**No further analysis.** No dead-link check, no clusters, no report, no chat
output.

Commit only if the generated index files actually changed:

```bash
cd <consumer repo root>
if ! git diff --quiet <index directory>; then
  git add <index directory> && git commit -m "chore(wiki): daily index update"
fi
```

That's it. The daily run is silent — the result is visible only in the git log.

---

## Full mode — interactive or weekly

Everything below applies to the full skill run. Stop here on `--silent`.

### Phase 1: Indexer run + graph build

Run `indexer_command` (verbose if supported), plus the graph builder if
present. Parse the output: stats (total files, tags, areas), new files since
the last run. A deterministic graph build (no embeddings, no vector store)
sourced from frontmatter + markdown links — plus state-backend foreign keys,
if the consumer has a state backend — keeps results reproducible.

### Phase 2: Dead-link detection

For every markdown file in the knowledge store: extract markdown links and
`related:` frontmatter entries, check whether the target file exists.

Output: a list of `file:line → broken target`, with the likely correct path
when it's inferable (e.g. a relative path that's one directory off).

### Phase 3: Frontmatter drift

Check that all knowledge-layer and project files have:
- `title`
- `type`
- non-empty `areas`
- `date` set (ISO format)

Output: a list of files with the missing/broken field per file.

### Phase 4: Tag drift

Detect similar-but-different tags (aliases, typos) via Levenshtein distance
≤ 2 between tag pairs — e.g. `deployment` vs. `deploy`, a project's long
name vs. its short slug.

Output: pairs with usage counts and a consolidation suggestion:
`"deployment" (4) ↔ "deploy" (1) — consolidate?`

### Phase 5: Cluster proposals

Find topic areas with ≥3 files in their raw-capture layer (or tagged as
session logs) → offer compression into the knowledge layer as one condensed
note.

Output: `raw layer of <area>: N related files on <topic> → compress into
one note?`

### Phase 6: Stale detection

Files with `status: active` but unchanged for >90 days → flag.

Output: file + days since last change + question: set `status: archived`,
or is this an active thread?

## Output format

```
━━━ WIKI-MAINTAIN [date] ━━━

Index: X files, Y tags, Z areas
   ↑ N new files since last run

Dead links: [N]
   [list]

Frontmatter drift: [N]
   [list]

Tag drift: [N]
   [list]

Cluster proposals: [N]
   [list]

Stale: [N]
```

## After user approval

- **Fix dead links:** edit the affected files (when the target is clear)
- **Complete frontmatter:** per-file fixes (via a migration helper if the
  consumer has one)
- **Consolidate tags:** batch replace across files, then re-run the indexer
- **Compress clusters:** invoke the `research` skill in aggregation mode
- **Archive stale files:** set frontmatter `status: archived`

## Commit guard (full mode)

Even after a full-mode run: only commit if changes were actually made (fixes,
frontmatter updates, tag consolidation).

```bash
cd <consumer repo root>
if ! git diff --quiet; then
  git add <changed files>
  git commit -m "chore(wiki): weekly maintenance [date]"
fi
```

No empty commit when the run only read/analyzed.

## Automation

Typical wiring (consumer-side):
1. Daily maintenance routine — silent mode (indexer only)
2. Weekly maintenance routine — full mode (dead links, clusters, drift)
3. After every `digest` run (indexer re-run, silent)
4. After every `research` run (indexer re-run, silent)
5. Manually via `/wiki-maintain`

## Anti-patterns

- Don't commit everything on every run — only when fixes were applied
- Don't consolidate tags without user approval (cross-area semantics can matter)
- Don't auto-delete dead links — they can point at a file that's planned but
  not yet created
