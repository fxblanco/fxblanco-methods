---
name: sanitize-prompt
description: >
  Sanitize a large burst-dictated prompt BEFORE acting: separate the real goal
  from the noise, mirror the intent in one line, and ask exactly one clarifying
  question when the goal is unclear or several asks are bundled. Auto-invoked by
  the sanitize-prompt UserPromptSubmit hook on any large prompt; also on
  "/sanitize-prompt", "was ist mein ziel hier", "prüf meinen prompt", "sortier
  das mal", "was will ich eigentlich".
---

# sanitize-prompt

The user burst-works: they dictate long dumps of feedback and context, and the
actual goal is often buried or implied. This skill runs BEFORE you act on such a
prompt. Its job is not to answer — it is to make the intent watertight first.

The trigger hook is dumb (it only measures size). This skill is the brain.

## The protocol

**1. Split signal from noise.**
Read the whole dump. Separate the ONE desired end-state (signal) from context,
tangents, and thinking-aloud (noise). Most of a burst prompt is noise around one
real ask.

**2. State the goal in one sentence.**
"The end-state the user wants is: ___." If you cannot fill that blank cleanly,
the prompt is not clear yet — go to step 4.

**3. Check the known burst failure-modes** (any hit → treat as unclear):
- **Bundled asks.** Several distinct jobs in one dump with no priority. Don't
  guess the order — surface the bundle.
- **Pronoun / actor ambiguity.** Dictation mixes "ich" / "du" / "er"; unclear who
  does what. Ask, don't assume.
- **Process-logic, not a task.** "After X comes Y" is a thought, not an
  instruction. Confirm whether an action is actually wanted.
- **Implausible number.** A value that looks off is usually a unit/typo issue —
  flag it, don't build a story around it.
- **Contradiction.** Two asks that can't both be true.

**4. Decide — and do NOT nag.**

- **Clear** (goal fills the blank, no failure-mode hit): mirror it in ONE line
  and go straight to work. Format:
  > Ziel: <end-state>. Ich mache <next action>. Brauch <blocker, if any>. Okay?
  Then proceed. No extra questions.

- **Unclear** (blank won't fill, or a failure-mode hit): ask **exactly ONE**
  crisp clarifying question. Give at most 2 named options plus the context to
  pick fast, and say which you'd choose. Do nothing else until answered.

## Rules

- One line to mirror, or one question to clarify. Never both, never more.
- Never silently pick an interpretation of an ambiguous dump and run with it.
- Clear prompt → zero friction. This skill must not slow down a clean ask.
- Keep exact paths, commands, numbers, and code from the prompt unchanged.
- You are sanitizing intent, not rewriting the user's words back at them.
