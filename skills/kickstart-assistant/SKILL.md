---
name: kickstart-assistant
description: >
  Mode assistant for project re-ignition — bring a dormant or stuck project
  back to life. Pulls the last known state together from every source the
  host actually has (memory, knowledge store, task system, recent assistant
  sessions, external trackers, git), identifies the continue point, and
  directly completes what can be completed (drafts, scripts, research, plan
  commits). Triggers: "kickstart [project]", "get going on [project]",
  "start [project]", "where were we on [project]", "project X is stuck
  somewhere" (German equally: "loslaufen [Projekt]", "lauf los", "fang an
  mit", "bring [Projekt] voran", "leg los mit", "wieder rein in [Projekt]",
  "wo standen wir bei"). Also when a planning routine identifies a focus and
  the user says "okay, let's do that".
---

# Kickstart-Assistant — project re-ignition

Goal: don't analyze — start. Pull the context together for one project,
complete immediately executable tasks, and stage plans for the bigger
pieces — so the user only has to say "go" or finds the finished output.

---

## Step 1: Identify the project

Derive from the user's input or context:
- Which project? (name, area)
- Is there a concrete focus? ("the payment integration", "the store
  submission", …)
- Timeframe? (today / this week / by a deadline)

If unclear: ask one short question. Don't guess.

---

## Step 2: Gather context (parallel, everything)

Goal: reconstruct the **last continue point** — the place where the project
was last active and where the next step picks up. Query all sources in
parallel, not serially. Use whichever of these source classes the host
actually has (capability file + host configuration decide what exists):

**Memory pointer (first — cheapest lookup):**
- the project's entry in cross-session memory
  (`runtimes.<runtime>.memory_path`): persistent project summary — status,
  stakeholders, last decisions. If present, it's the fastest entry, often
  already "where we were".
- if there's no dedicated project memory file: grep the memory index for the
  project slug, then check related feedback/pattern entries.

**Knowledge store (per `methods/pkm.md`):**
- the area's entry-point doc — current project status
- existing notes, decisions, old kickstart prep files in the knowledge layer
- the project's multi-file folder (spec, plan, audit), if one exists
- open tasks for this project from the consumer's task/state system —
  whatever the capability file declares as the live state source. Query the
  live source; never a stale mirror.

**Recent assistant sessions (decisive for "where were we"):**
- search recent session transcripts for the project slug, newest first; open
  the top hits (the last user message + last assistant message are usually
  enough for the last state).
- if that's unavailable or too expensive: skip AND note it in the report
  ("sessions not checked"). Never fail silently.

**External work trackers (if the consumer has them):**
- issue tracker: open items assigned to the user for this project, by last
  update
- meeting-notes / documentation system: recent pages mentioning the project;
  look for action items that concern the user and aren't tracked as tasks yet

**Git (last known state):**
- `git log --oneline -10` and `--since="14 days ago"` on the project's
  repo(s)

**Synthesis:** formulate the *one* continue point from all sources — what
was the last active step, what comes next. If the sources contradict each
other (docs say phase A in review, tracker says in progress, the last
session worked on phase B): put that in the report — don't suppress it.

---

## Step 3: Classify tasks

All open tasks + found action items into two buckets:

**The assistant can complete directly** (no user input needed):
- research: "check whether X exists / how Y works"
- context summary: "what do we have on Z so far?"
- draft: "draft for a mail / document / PR description"
- implementation plan: "how would we build A?"
- quick setup: script, config, scaffold

**Needs the user:**
- decisions with external impact
- code deploys, sending messages, external actions
- creative direction calls
- anything requiring physical access

---

## Step 4: Kickstart (direct execution)

**Core rule — produce artifacts, not tasks.** If the assistant mentions
something in the kickstart output, it must also have done it: executed
directly, or delivered as a ready-to-send draft / runnable script / finished
research / committed plan. Create tasks only where *exclusively* the user
can act (a personal phone call, a decision with external impact, a deploy
behind a guardrail).

Background: this rule exists because an earlier version of this skill
produced a list of 11 follow-up tasks instead of 11 finished drafts. A
growing task list at the end of a kickstart is **work postponed**, not a
project started. Anti-signal.

**For every "assistant can" task:** execute directly, store the result in
the knowledge store. Research results, drafts (mail/doc/PR text verbatim),
and plans go into the area's knowledge layer as
`prep-<YYYY-MM-DD>-<slug>.md`.

For implementation plans: concrete and executable. Format:

```markdown
# Implementation plan: [feature/task]
## Context
[what I found — max 5 sentences, incl. the continue point from step 2]
## Approach
[concrete steps 1–N with time estimates]
## Risks / open questions
[what's still unclear]
## Next step on go
[first action once the user approves]
```

**For code tasks:** have the plan ready, scaffold where sensible, then ask
for go.

**Sanity check before step 5:** if the report only lists tasks and links no
artifacts (drafts/scripts/plans), the kickstart has not happened — go back
to step 4 and produce at least *one* artifact before reporting.

---

## Step 5: Report the result

Terse + action-oriented, no status enumeration. Continue point first, then
what the assistant did, then what the user can do. No meta-fluff, no
"active projects" dump.

```
[project] — continue point: [one line: last active step + next step]

Done:
- [artifact 1 → path] — [1 line on what's inside]
- [artifact 2 → path] — [1 line]

Ready for go (1-click):
1) [draft/plan/action] → [path] — go?
2) [draft/plan/action] → [path] — send / adjust / skip?

Needs you:
- [real decision — no recommendation possible, because …]

Blockers (if any):
- [what's missing, with a concrete follow-up suggestion]
```

If everything is already done: just continue point + "Done" + the next
sensible step — no empty "Needs you"/"Blockers" blocks.
If it's plan-only: continue point + plan path + go question.

---

## Model note

Don't run this skill on cheap models. Context gathering across several
sources needs capacity for synthesis. When called as a sub-agent from a
weekly planning routine: use a high-capability model.

---

## Persistence

Always store results:
- plans + research → the area's knowledge layer,
  `prep-<YYYY-MM-DD>-<slug>.md`
- new tasks that emerge → the consumer's task/state system (the live
  source declared in the capability file), never into dead markdown lists
- no git commit from this skill — that's the planning routine's or the
  user's job.
