# /learn — pattern extraction into cross-session memory

Method core — the single source. Per-consumer adapters (a Claude Code command
file, a Codex skill wrapper) are generated at sync time; their frontmatter may
differ per surface, this content does not.

Adapted from the community "ECC" `/learn` command pattern. Writes **directly
into the assistant's existing cross-session memory format**, not into a
second, parallel system.

Different from `lessons`: `learn` captures **reusable behavior patterns and
facts** (who does what, where things live, how the user wants things done) in
memory; `lessons` captures **condensed post-mortem insights from mistakes**
in the knowledge store.

## When to use

Manual trigger at the end of a session OR on demand when the user says:
- "learn" / "/learn"
- "remember this" / "extract that as a pattern"
- "this keeps happening"
- (German equally: "merk dir das", "extrahier das mal als pattern",
  "das passiert öfter")

**Do NOT auto-trigger** on every session — that floods memory with junk.

## What to extract

Scan the session for these pattern types:

### 1. Feedback patterns (corrections + confirmations)
- The user corrected you: "not like that, like this" → `feedback` memory
- The user confirmed an unusual approach: "yes, exactly, do it that way" → `feedback` memory
- **Core question:** would this correction help again in a future session?

### 2. Project patterns (who does what, when, why)
- New people / roles / responsibilities learned → `project` memory
- Deadlines, stakeholder asks, running initiatives → `project` memory

### 3. Reference patterns (where things live)
- External systems you'll need again next time (a tracker project, a chat
  channel, a dashboard URL) → `reference` memory
- Repo paths, tool configs, service endpoints → `reference` memory

### 4. User patterns (about the user themselves)
- A new role / responsibility / skill / preference of the user → `user` memory

### Anti-patterns — do NOT extract
- Code patterns that live in the repo itself → the assistant reads them next time anyway
- Git history / commit messages → `git log` is authoritative
- Debugging solutions → the fix is in the code, the commit message has context
- Things already documented in the root instruction files
- Ephemeral state (current task, in-progress work)

## Output format

One file per extracted pattern, written to the consumer's memory location
(`runtimes.<runtime>.memory_path` in `.methodik-capabilities.json`), named
`<type>_<slug>.md`:

```markdown
---
name: {{short title}}
description: {{one-line hook that will match later memory searches — be specific}}
type: {{user | feedback | project | reference}}
---

{{body — for feedback/project additionally:}}
**Why:** {{why this rule/fact — typically the user referenced an incident or a preference}}
**How to apply:** {{when/where this applies in future sessions}}
```

Also update the memory index file (e.g. `MEMORY.md`):
```markdown
- [Title](type_slug.md) — one-line hook
```

## Path resolution

1. Use the memory location of the current project/consumer, from the
   capability file (`runtimes.<runtime>.memory_path`). Create it if missing.
2. **Fallback:** the consumer's primary/default memory location — if the
   current project has no memory folder of its own.

## Process

1. **Review the session** — what was recurring, corrected, or new?
2. **Classify** — which memory type fits?
3. **Duplicate check** — does a similar memory already exist? If yes → update
   instead of writing a new one.
4. **Show a draft in chat** — before writing, the user sees the file + the
   index entry.
5. **On user OK** — write + update the index.
6. **On user stop** — discard, no file.

## Examples

### Example 1: recurring correction
**Session context:** the user had to explain three times that a partner's
system is out of scope — "that's theirs, we don't touch it."

```markdown
---
name: Partner shop system is out of scope
description: The partner runs their own shop system; our engagement covers only the data product on top of it
type: project
---

The partner operates their own shop. Our relationship covers only the
data/AI product layered on top — not the shop itself.

**Why:** The user clarified three times that they don't work on the shop
itself — "that's the partner's own thing."
**How to apply:** For tasks on the data product, do NOT look into the shop
repo. If a shop question comes up → ask the partner directly.
```

### Example 2: new reference
**Session context:** a teammate pointed to a new log endpoint for debugging.

```markdown
---
name: Agent runtime logs endpoint
description: Live logs of all agent heartbeats at <ops-host>/logs?since=...
type: reference
---

Heartbeat logs of all agents:
- URL: `https://<ops-host>/logs?since=24h`
- Filter: `?agent=<name>`
- JSON response, searchable

**Why:** Named as the central debug source when a heartbeat is missing.
**How to apply:** For agent status questions or missing standups → check
here first instead of the runtime UI.
```

## Notes

- **One pattern per file.** Three specific beats one catch-all.
- **Short, precise description.** It gets matched by memory search — generic = bad.
- **No date in the body.** Dates make memory look stale fast. File mtime is enough.
- **Update existing memory instead of duplicating.** Grep first, then write.
- **No trivia.** "User likes coffee" → reject.
