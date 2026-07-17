---
name: council
description: >
  Council — structured decision support with 5 voices + a synthesizer.
  Use this skill whenever the user faces a real decision with trade-offs —
  including when they only say "let's think this through", "I'm torn",
  "pros and cons", "what would you do?", "should I do X or Y",
  "help me decide", "Council", or "/council <topic>"
  (German triggers equally: "lass uns das durchdenken", "bin unentschlossen",
  "Pro/Contra", "was würdest du machen?", "ich stehe vor der Wahl",
  "Beratung", "Entscheidung treffen", "Rat holen").
  Also for architecture forks, pivot decisions, priority conflicts, or when the
  user is weighing several roughly equivalent options — then offer proactively:
  "Want me to put this to the Council?"
---

# Council

Five independent voices argue a decision from fixed, complementary lenses; a
sixth voice synthesizes. Three rounds: initial positions → anonymized
cross-review → synthesis. The value comes from the voices being genuinely
isolated from each other in rounds 1–2.

## When to use (trigger awareness)

Council pays off for real decision dilemmas with at least two serious options
and tangible trade-offs — e.g. make-vs-buy, architecture forks, priority
conflicts, direction decisions, resource allocation. Not for plain information
lookups or quick wins. If the user hesitates or is weighing multiple factors
against each other: proactively suggest a Council.

## Trigger

The user types `/council <topic>` or invokes the skill manually with:
- `topic` — the question / dilemma (1–3 sentences)
- optional `context` — path to a relevant note, spec, or decision doc

## Personas

Load the 6 persona files (relative to this skill's directory):
- `personas/asha.md` — Architect
- `personas/kai.md` — Pragmatist
- `personas/nox.md` — Critic
- `personas/mira.md` — User-Advocate
- `personas/lior.md` — Curator
- `personas/tov.md` — Synthesizer

## Round 1 — Initial voices (parallel)

Dispatch 5 parallel, isolated sub-agents using the host's parallel-work
mechanism (see `runtimes.<runtime>.parallel_work_mechanism` in the consumer's
`.methodik-capabilities.json`). A mid-tier model is sufficient. Each gets:
- System: the content of its own persona file
- User input: `<topic>\n\nContext: <context-or-relevant-notes>`
- Tools: read + glob access for Lior (so it can look up the consumer's
  knowledge store); the others need none.

Output per voice: 3–8 sentences per the persona's format.

Collect the 5 answers as `responses_round_1`.

## Round 2 — Cross-review (parallel)

Dispatch 5 parallel sub-agents. Each gets:
- System: its own persona file + the instruction "You receive 4 anonymized
  positions from other voices. Rank them 1–4 with 1–2 sentences of critique
  per ranking. Your own position is not among them."
- User input: the anonymized 4 answers of the *other* voices (never its own)

Anonymization: voice names are mapped to "Voice A" … "Voice D". Keep the
mapping to resolve later.

Output per voice: a markdown list with ranking + critique.

Collect as `rankings_round_2`.

## Round 3 — Synthesis (Tov)

One synthesizer sub-agent (isolated). Gets:
- System: the Tov persona file
- User input: the 5 round-1 positions (voice names resolved) + the 5 round-2
  rankings (voice names resolved)

Output: markdown in the format defined in `tov.md` (Recommendation + Reasoning
+ Disagreement + User-Action).

## Memory file

Write the full transcript to the consumer's memory location — take
`memory_path` from the consumer's `.methodik-capabilities.json`
(`runtimes.<runtime>.memory_path`) and create:

`<memory_path>/council/<topic-slug>-YYYY-MM-DD.md`

```markdown
# Council: <topic>

date: <YYYY-MM-DD>
participants: Asha, Kai, Nox, Mira, Lior, Tov

## Topic

<topic + context>

## Round 1 — Initial Positions

### Asha (Architect)
<response>

### Kai (Pragmatist)
<response>

### Nox (Critic)
<response>

### Mira (User-Advocate)
<response>

### Lior (Curator)
<response>

## Round 2 — Cross-Review

### Asha's Rankings
1. <other-voice> — <critique>
2. ...

### Kai's Rankings
...

[etc., 5 sections]

## Round 3 — Synthesis (Tov)

<Tov output>
```

Write the file. Print the path back to the user.

## Tools for sub-agents

- Asha, Kai, Mira, Nox: no tool access (pure reasoning).
- Lior: read + glob (to look up the consumer's knowledge store — lessons,
  notes, memory).
- Tov: read (to re-check the round-1/2 material if needed).

## Token budget

5 voices × ~500 output tokens + 5 reviews × ~400 + 1 synthesis × ~800
≈ 5,000 output tokens, plus ~2,000 input tokens each. On a mid-tier model
that's cents per Council run. Acceptable.

## Hard rules

- Never trigger a Council from a cron job or any autopilot.
- Never run a Council without an explicit topic.
- Never modify the personas during a skill run — persona edits go into the
  persona files, deliberately.
