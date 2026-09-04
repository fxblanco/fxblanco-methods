#!/usr/bin/env node
/**
 * sanitize-prompts.js — UserPromptSubmit hook (DUMMER Trigger)
 *
 * Rolle: Felix burst-diktiert oft lange Feedback-Dumps. Dieser Hook DENKT NICHT.
 * Er misst nur die Größe (deterministisch, billig). Ist der Prompt groß, flüstert
 * er Claude EINE Anweisung zu: den Skill `sanitize-prompt` aufrufen — dort liegt
 * das intelligente Intent-/Ziel-Protokoll.
 *
 * Kanonische Quelle dieses Hooks: fxblanco-methods/skills/sanitize-prompt/hook/
 * Diese Kopie hier (~/.claude/hooks/) ist die INSTALLIERTE Fassung (global).
 *
 * Tuning: THRESHOLD unten (Zeichen). Höher = seltener. Nie blockierend: bei
 * jedem Fehler still exit 0, damit der Prompt nie hängt.
 */

const THRESHOLD = 900; // Zeichen. Ab hier gilt ein Prompt als "groß / Burst-Diktat".

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    if (process.stdin.isTTY) return resolve("");
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (c) => (data += c));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", () => resolve(""));
    setTimeout(() => resolve(data), 2000); // Safety-Timeout
  });
}

(async () => {
  try {
    const raw = await readStdin();
    if (!raw.trim()) return process.exit(0);

    let prompt = "";
    try {
      prompt = String(JSON.parse(raw).prompt || "");
    } catch {
      return process.exit(0); // kein valides JSON → nichts tun
    }

    const text = prompt.trim();
    if (!text || text.startsWith("/")) return process.exit(0); // Slash-Commands raus
    if (text.length < THRESHOLD) return process.exit(0);

    const chars = text.length;
    const words = text.split(/\s+/).filter(Boolean).length;

    const context = [
      `SANITIZE-PROMPT-HOOK: Großer Prompt (~${chars} Zeichen, ~${words} Wörter — typisches Burst-Diktat).`,
      `Bevor du irgendetwas tust: rufe den Skill \`sanitize-prompt\` auf (das detaillierte Intent-/Ziel-Protokoll) und folge ihm.`,
      ``,
      `Falls der Skill nicht verfügbar ist, Minimal-Protokoll:`,
      `1. Extrahiere das eigentliche ZIEL / den Endzustand in EINEM Satz.`,
      `2. Ziel klar UND nächste Aktion konkret? → Spiegle es in EINER Zeile ("Ziel: X. Ich mache Y.") und lauf los.`,
      `3. Ziel unklar, widersprüchlich, ODER mehrere ungeordnete Aufträge drin? → Stelle GENAU EINE kurze Rückfrage, bevor du handelst. Rate nicht.`,
      `Nicht nerven: ist alles klar, keine Extra-Frage — nur die eine Ziel-Zeile.`,
    ].join("\n");

    process.stdout.write(
      JSON.stringify({
        hookSpecificOutput: {
          hookEventName: "UserPromptSubmit",
          additionalContext: context,
        },
      })
    );
    process.exit(0);
  } catch {
    process.exit(0); // niemals den Prompt blockieren
  }
})();
