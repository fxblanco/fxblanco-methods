#!/usr/bin/env bash
# The single canonical sync script for fxblanco-methods. Lives ONLY here —
# consumers invoke it via the submodule path (.vendor/fxblanco-methods/scripts/sync-consumer.sh),
# never copy it locally (a copy is itself a drift source, see PLAN.md Rev.5 Round-4 Finding #4).
#
# Usage, run from the CONSUMER repo root:
#   .vendor/fxblanco-methods/scripts/sync-consumer.sh sync    # materialize + write manifest
#   .vendor/fxblanco-methods/scripts/sync-consumer.sh check   # read-only integrity check (routines use this)
#
# Requires: jq, git, sha256sum (or shasum on macOS).
set -euo pipefail

MODE="${1:-sync}"
CONSUMER_ROOT="$(pwd)"
VENDOR="$CONSUMER_ROOT/.vendor/fxblanco-methods"
SOURCE_ROOT="$(cd "$(dirname "$0")/.." && pwd)"  # fxblanco-methods repo root (may be $VENDOR or a dev checkout)
CAPS_FILE="$CONSUMER_ROOT/.methodik-capabilities.json"
MANIFEST_SRC="$SOURCE_ROOT/manifest.json"
MANIFEST_OUT="$CONSUMER_ROOT/.methodik-manifest.json"

hash_file() { shasum -a 256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }
hash_dir() {
  find "$1" -type f | sort | xargs -I{} shasum -a 256 {} 2>/dev/null | shasum -a 256 | cut -d' ' -f1
}

fail() { echo "sync-consumer: FEHLER: $*" >&2; exit 1; }

[ -d "$VENDOR" ] || fail "kein .vendor/fxblanco-methods Submodule gefunden — 'git submodule update --init' fehlt?"
[ -f "$CAPS_FILE" ] || fail "kein .methodik-capabilities.json im Consumer-Root — Schema siehe fxblanco-methods/capabilities.schema.json"
command -v jq >/dev/null || fail "jq fehlt"

# ── Capability-Validierung (Pflichtfelder + conditional requirements) ──────
for field in runtimes state_backend retrieval_stages instruction_modules enabled_surfaces; do
  jq -e "has(\"$field\")" "$CAPS_FILE" >/dev/null || fail "capabilities: Pflichtfeld '$field' fehlt"
done
STATE_BACKEND=$(jq -r '.state_backend' "$CAPS_FILE")
if [ "$STATE_BACKEND" != "none" ]; then
  jq -e 'has("state_endpoint") and has("state_access")' "$CAPS_FILE" >/dev/null \
    || fail "capabilities: state_backend='$STATE_BACKEND' verlangt state_endpoint + state_access"
fi
ENABLED_SURFACES=$(jq -r '.enabled_surfaces | join(",")' "$CAPS_FILE")

# ── Integritäts-Check (auch von 'sync' vorab gelaufen, 'check' macht NUR das) ──
if [ -f "$MANIFEST_OUT" ]; then
  DIRTY=$(git -C "$VENDOR" status --porcelain)
  if [ -n "$DIRTY" ]; then
    fail "Submodule .vendor/fxblanco-methods hat lokale Änderungen (dirty) — SHA-Gleichheit reicht nicht als Integritäts-Beweis. 'git -C $VENDOR status' prüfen."
  fi
  EXPECTED_SHA=$(jq -r '.sha' "$MANIFEST_OUT")
  ACTUAL_SHA=$(git -C "$VENDOR" rev-parse HEAD)
  if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ] && [ "$MODE" = "check" ]; then
    fail "Submodule-SHA ($ACTUAL_SHA) weicht vom letzten Sync-Manifest ($EXPECTED_SHA) ab — 'sync' erneut laufen lassen."
  fi
fi

if [ "$MODE" = "check" ]; then
  echo "sync-consumer: OK (read-only Integritäts-Check bestanden, SHA=$(git -C "$VENDOR" rev-parse HEAD))"
  exit 0
fi

[ "$MODE" = "sync" ] || fail "unbekannter Modus '$MODE' (erwartet: sync|check)"

SHA=$(git -C "$VENDOR" rev-parse HEAD)
ARTIFACT_COUNT=$(jq '.artifacts | length' "$MANIFEST_SRC")
echo "sync-consumer: SHA=$SHA, $ARTIFACT_COUNT Artefakt(e) im Manifest, enabled_surfaces=[$ENABLED_SURFACES]"

MATERIALIZED_HASHES="[]"
for i in $(seq 0 $((ARTIFACT_COUNT - 1))); do
  ART=$(jq ".artifacts[$i]" "$MANIFEST_SRC")
  ID=$(echo "$ART" | jq -r '.id')
  TARGET_TYPE=$(echo "$ART" | jq -r '.target_type')
  ART_SURFACES=$(echo "$ART" | jq -r '.surfaces | join(",")')

  for surface in claude codex; do
    echo "$ART_SURFACES" | grep -q "$surface" || continue
    echo "$ENABLED_SURFACES" | grep -q "$surface" || continue

    case "$TARGET_TYPE" in
      skill)
        target_root=$([ "$surface" = "claude" ] && echo ".claude/skills" || echo ".agents/skills")
        target="$CONSUMER_ROOT/$target_root/$ID"
        rel="$(python3 -c "import os;print(os.path.relpath('$VENDOR/skills/$ID','$CONSUMER_ROOT/$target_root'))" 2>/dev/null || echo "../../.vendor/fxblanco-methods/skills/$ID")"
        mkdir -p "$(dirname "$target")"
        [ -L "$target" ] && [ "$(readlink "$target")" = "$rel" ] && continue
        rm -rf "$target"
        ln -s "$rel" "$target"
        echo "  materialized ($surface): $target_root/$ID"
        ;;
      command+skill)
        if [ "$surface" = "claude" ]; then
          CLAUDE_TARGET=$(echo "$ART" | jq -r '.claude_target')
          mkdir -p "$(dirname "$CONSUMER_ROOT/$CLAUDE_TARGET")"
          cp "$VENDOR/skills/$ID/METHOD.md" "$CONSUMER_ROOT/$CLAUDE_TARGET" 2>/dev/null || true
          echo "  materialized (claude command): $CLAUDE_TARGET"
        fi
        if [ "$surface" = "codex" ]; then
          CODEX_TARGET=$(echo "$ART" | jq -r '.codex_target')
          mkdir -p "$(dirname "$CONSUMER_ROOT/$CODEX_TARGET")"
          # File-to-file copy (renaming METHOD.md -> SKILL.md), NOT `cp -r` of the
          # source dir into the already-mkdir'd target dir (that nests source-inside-target,
          # e.g. .agents/skills/learn/learn/METHOD.md instead of .agents/skills/learn/SKILL.md).
          cp "$VENDOR/skills/$ID/METHOD.md" "$CONSUMER_ROOT/$CODEX_TARGET" 2>/dev/null || true
          echo "  materialized (codex skill): $CODEX_TARGET"
        fi
        ;;
      *)
        fail "unbekannter target_type '$TARGET_TYPE' bei Artefakt '$ID'"
        ;;
    esac
  done

  H=$(hash_dir "$VENDOR/skills/$ID" 2>/dev/null || echo "n/a")
  MATERIALIZED_HASHES=$(echo "$MATERIALIZED_HASHES" | jq --arg id "$ID" --arg h "$H" '. + [{"id":$id,"hash":$h}]')
done

# ── Root-Injection: pro instruction_module ein eigener SHA-markierter Block ──
for mod in $(jq -r '.instruction_modules[]' "$CAPS_FILE"); do
  MOD_FILE="$SOURCE_ROOT/methods/$mod.md"
  [ -f "$MOD_FILE" ] || MOD_FILE="$SOURCE_ROOT/personal-profile/$mod.md"
  [ -f "$MOD_FILE" ] || { echo "  WARN: instruction_module '$mod' nicht gefunden, übersprungen"; continue; }
  for root_file in CLAUDE.md AGENTS.md; do
    [ -f "$CONSUMER_ROOT/$root_file" ] || continue
    MARKER_BEGIN="<!-- BEGIN fxblanco-methods:$mod sha=$SHA -->"
    MARKER_END="<!-- END fxblanco-methods:$mod -->"
    python3 - "$CONSUMER_ROOT/$root_file" "$MOD_FILE" "$mod" "$SHA" <<'PYEOF'
import re, sys
root_path, mod_path, mod, sha = sys.argv[1:5]
with open(root_path) as f: root = f.read()
with open(mod_path) as f: content = f.read()
begin = f"<!-- BEGIN fxblanco-methods:{mod} sha="
end = f"<!-- END fxblanco-methods:{mod} -->"
block = f"<!-- BEGIN fxblanco-methods:{mod} sha={sha} -->\n{content}\n{end}\n"
pattern = re.compile(re.escape(begin) + r".*?" + re.escape(end) + r"\n?", re.DOTALL)
if pattern.search(root):
    root = pattern.sub(block, root)
else:
    root = root.rstrip("\n") + "\n\n" + block
with open(root_path, "w") as f: f.write(root)
PYEOF
  done
done

# ── Manifest schreiben (KEIN Timestamp — Idempotenz-Beweis: zweiter Sync = kein Diff) ──
jq -n --arg sha "$SHA" --argjson skills "$MATERIALIZED_HASHES" \
  '{sha: $sha, artifacts: $skills}' > "$MANIFEST_OUT"

echo "sync-consumer: fertig, $MANIFEST_OUT geschrieben"
