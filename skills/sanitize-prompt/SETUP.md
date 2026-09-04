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
2. The hook measures its size. Small / slash-command → passes through untouched.
3. Large (≥ `THRESHOLD` chars, default 900) → the hook injects a directive telling
   Claude to invoke the `sanitize-prompt` skill before acting.
4. The skill separates the real goal from the noise, mirrors it in one line, and
   asks exactly one clarifying question only when the intent is unclear.

The hook never blocks a prompt (any error → silent pass). The skill must not nag:
a clear prompt gets a one-line goal mirror and nothing else.

## Tuning

Edit `THRESHOLD` in the hook script (both the canonical copy here and the installed
copy in `~/.claude/hooks/`). Higher = fires less often.

> Note: hook and skill are currently a documented manual install. If this pattern
> proves useful, the follow-up is a `hook` target_type in `manifest.json` +
> `sync-consumer.sh` so the hook auto-installs and self-updates like skills do.
