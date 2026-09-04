#!/usr/bin/env node
/**
 * sanitize-prompts.js — UserPromptSubmit hook (DUMMER Trigger)
 *
 * Rolle: Felix burst-diktiert oft lange, wirre Feedback-Dumps. Dieser Hook
 * DENKT NICHT (kein LLM). Er entscheidet nur deterministisch: sieht dieser
 * Prompt nach Burst-Diktat aus? Wenn ja, flüstert er Claude EINE Anweisung zu:
 * den Skill `sanitize-prompt` aufrufen — dort liegt das intelligente Intent-/
 * Ziel-Protokoll (das echte Intent-Erkennen passiert im Skill, nicht hier).
 *
 * Trigger = Burst-FORM statt reiner Länge:
 *   feuert, wenn Länge >= LENGTH_FLOOR  ODER  Burst-Score >= SCORE_FLOOR.
 * So werden kurze WIRRE Prompts gefangen, kurze KLARE bleiben in Ruhe.
 *
 * Kanonische Quelle: fxblanco-methods/skills/sanitize-prompt/hook/
 * Installierte Kopie: ~/.claude/hooks/sanitize-prompts.js (global).
 *
 * Nie blockierend: bei jedem Fehler still exit 0.
 */

const LENGTH_FLOOR = 400; // Zeichen. Ab hier gilt ein Prompt als "lang genug" zum Prüfen.
const SCORE_FLOOR = 2; // Burst-Signale. Ab hier feuert er auch unter LENGTH_FLOOR.

function readStdin() {
  return new Promise((resolve) => {
    let data = "";
    if (process.stdin.isTTY) return resolve("");
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (c) => (data += c));
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", () => resolve(""));
    setTimeout(() => resolve(data), 2000);
  });
}

// Zählt Burst-Signale: Verzweigung, Unsicherheit, Ich/Du-Mix, viele Teilsätze.
function burstScore(text) {
  const t = text.toLowerCase();
  let score = 0;
  const ramble = (t.match(
    /\b(oder|vielleicht|irgendwie|iwie|so wie|weiß nicht|weiss nicht|glaube|keine ahnung|halt|einfach mal|mal gucken|mal schauen)\b/g
  ) || []).length;
  if (ramble >= 3) score++; // viel Hedging / Verzweigung
  if ((text.match(/\?/g) || []).length >= 2) score++; // mehrere Fragen
  if (/\bich\b/.test(t) && /\b(du|dir|dich)\b/.test(t)) score++; // Ich/Du gemischt
  const commas = (text.match(/,/g) || []).length;
  if (text.length >= 200 && commas >= 4) score++; // langer Schachtelsatz
  return score;
}

(async () => {
  try {
    const raw = await readStdin();
    if (!raw.trim()) return process.exit(0);

    let prompt = "";
    try {
      prompt = String(JSON.parse(raw).prompt || "");
    } catch {
      return process.exit(0);
    }

    const text = prompt.trim();
    if (!text || text.startsWith("/")) return process.exit(0); // Slash-Commands raus

    const chars = text.length;
    const score = burstScore(text);
    const isBurst = chars >= LENGTH_FLOOR || score >= SCORE_FLOOR;
    if (!isBurst) return process.exit(0);

    const words = text.split(/\s+/).filter(Boolean).length;
    const why = chars >= LENGTH_FLOOR ? `${chars} Zeichen` : `Burst-Form erkannt (Score ${score})`;

    const context = [
      `SANITIZE-PROMPT-HOOK: Prompt sieht nach Burst-Diktat aus (${why}, ~${words} Wörter).`,
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
    process.exit(0);
  }
})();
