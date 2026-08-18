---
name: quick
description: >
  Compress the answer down to the N most important points as a short numbered
  list. Use when the user types "/quick", "/quick <number>" (e.g. "/quick 3"),
  "quick", or asks for "just the key points", "TL;DR", "top N takeaways", or
  the gist of a long answer or a topic. German equally: "kurzfassung", "nur
  die wichtigsten punkte", "auf den punkt", "top 3".
---

# quick

Give the most important takeaways as a short numbered list. Nothing else.

## Two modes

**Number given** (e.g. `/quick 3`, `/quick 5`)
- Return EXACTLY that many points, numbered 1..N.
- Ranked most important first.

**No number** (`/quick`)
- Return 3 points, ranked most important first.
- Add a 4th only if leaving it out would be misleading.

## Rules

- One idea per point. One line per point where you can.
- Plain words, no jargon. If a point needs a technical term, explain it inline
  in plain words.
- No intro, no outro, no "here are the key points". Just the numbered list.
- Keep exact paths, commands, numbers, and code unchanged.
- If the user runs `/quick` on your previous long answer, compress THAT answer.
  If they give a topic, give the N key points of the topic.
