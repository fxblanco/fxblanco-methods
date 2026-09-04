# sanitize-prompt — Setup

Two parts. The **skill** (`SKILL.md`) is the brain and is installed like any other
artifact via `sync-consumer.sh` (symlinked into `.claude/skills/sanitize-prompt`).

The **hook** (`hook/sanitize-prompts.js`) is the dumb trigger. It is Claude-Code
runtime wiring, NOT auto-installed by the sync script yet — install it once per
machine:

## 1. Install the hook script (global)

```bash
cp .vendor/fxblanco-methods/skills/sanitize-prompt/hook/sanitize-prompts.js \
   ~/.claude/hooks/sanitize-prompts.js
```

## 2. Wire it into `~/.claude/settings.json`

Add this entry to `hooks.UserPromptSubmit` (global settings = fires in every project):

```json
{
  "hooks": [
    {
      "type": "command",
      "command": "node \"/Users/felixblanco/.claude/hooks/sanitize-prompts.js\"",
      "timeout": 5,
      "statusMessage": "Checking prompt intent..."
    }
  ]
}
```

## How it works

1. You submit a prompt.
2. The hook checks its SHAPE, not just its length. Slash-command → passes through.
3. It fires when the prompt looks like a burst dump — either length ≥ `LENGTH_FLOOR`
   (default 400 chars) OR a burst-score ≥ `SCORE_FLOOR` (default 2). The score counts
   ramble signals: lots of branching/hedging words (oder / vielleicht / irgendwie …),
   two or more question marks, an ich+du actor mix, or one long comma-heavy sentence.
   So a short WIRR prompt is caught while a short CLEAR one stays silent.
4. On a fire, the hook injects a directive telling Claude to invoke the
   `sanitize-prompt` skill before acting.
5. The skill separates the real goal from the noise, mirrors it in one line, and
   asks exactly one clarifying question only when the intent is unclear.

The hook never blocks a prompt (any error → silent pass). The skill must not nag:
a clear prompt gets a one-line goal mirror and nothing else.

## Tuning

Edit `LENGTH_FLOOR` / `SCORE_FLOOR` in the hook script (both the canonical copy here
and the installed copy in `~/.claude/hooks/`). Higher `LENGTH_FLOOR` = fires less on
length; higher `SCORE_FLOOR` = fires less on burst-shape. Widen the ramble-word regex
in `burstScore()` to catch more dictation tics.

> Note: hook and skill are currently a documented manual install. If this pattern
> proves useful, the follow-up is a `hook` target_type in `manifest.json` +
> `sync-consumer.sh` so the hook auto-installs and self-updates like skills do.
