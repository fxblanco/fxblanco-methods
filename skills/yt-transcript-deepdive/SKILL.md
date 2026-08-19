---
name: yt-transcript-deepdive
description: >
  Deep-dive a whole set of long videos from ONE source (a channel, a
  playlist, or a hand-picked list) by pulling their transcripts, condensing
  each in its own subagent, and synthesizing a calibrated overall picture —
  e.g. "what does host/person X actually say across their recent episodes",
  "how does their guest mix or stance shift over time", sentiment or
  positioning across many episodes. Use when the user asks for a multi-video
  analysis, a channel/podcast deep-dive, or "look at the last N episodes and
  tell me the pattern". German equally: "mach mir einen Deepdive zu Kanal X",
  "was sagt Person Y in ihren letzten Folgen wirklich", "analysier die
  letzten N Folgen". NOT for a single video or URL — that is the `research`
  skill. NOT for text/web articles.
---

# yt-transcript-deepdive

Turn many long videos into one evidence-based picture, cheaply. The core
move: **pull + clean transcripts in the main thread (near-zero model
tokens), then hand ONE transcript to ONE subagent each** — the giant
transcripts never enter the main context, only the compressed summaries come
back.

Differs from `research` (single video/URL → one note). This is the
many-videos-from-one-source fan-out with a synthesis and rigor gates.

Requires `yt-dlp` on PATH (external CLI). Storage of the final note follows
[`storage-contract.md`](./storage-contract.md) + the consumer's
`.methodik-capabilities.json`; no path is hardcoded here.

## Inputs to settle first (ask if unclear)

- **Source:** a channel/playlist URL, or an explicit video list.
- **Selection:** how many + on what basis. Default split: top-K by reach
  **plus** M chosen for spread (viewpoint, topic, guest type) so the sample
  is not only the loud/viral episodes. **State the split explicitly.**
- **Time window** (e.g. this year).
- **Extraction target:** the ONE signal each worker pulls (e.g. "only the
  host's own statements/behaviour", "stance on topic Z", sentiment). This is
  what makes the fan-out cheap and focused.

## Pipeline

### 1. Discover
```bash
yt-dlp --flat-playlist --print "%(id)s|%(view_count)s|%(title)s" "<PLAYLIST_OR_CHANNEL_URL>"
```
`view_count` is often `NA` in flat mode — fetch real counts in step 3.

### 2. Select
Pick the target set by title/metadata against the agreed criteria. Note the
IDs. Titles themselves are signal (framing/editorialising) — keep them.

### 3. Pull transcript + metadata (the part that fights bot-blocking)
`yt-dlp` hits **"Sign in to confirm you're not a bot"** after a few rapid
requests. Two fixes, both needed:
- **Alternate player client** (no cookies): `--extractor-args
  "youtube:player_client=tv_embedded,web_safari,mweb"`.
- Sequential pulls with `sleep` (6–20s) between videos; for many/long videos
  run it as a background job so it is not killed by a foreground timeout.

`--print` forces simulate-mode (no subtitle files written), so get metadata
via `--write-info-json` in the SAME extraction call as the subs:
```bash
yt-dlp --no-warnings --skip-download \
  --write-auto-subs --sub-langs "<lang>-orig,<lang>" --sub-format vtt \
  --write-info-json \
  --extractor-args "youtube:player_client=tv_embedded,web_safari,mweb" \
  -o "s_%(id)s.%(ext)s" "https://youtu.be/<ID>"
```
`<lang>-orig` (e.g. `de-orig`) = the originally spoken track — better than a
machine-translated one. Read `view_count`/`duration` from `s_<ID>.info.json`.

### 4. Clean the VTT (auto-subs are heavily duplicated)
Auto-subtitles repeat each line (a growing copy with word timestamps + a
settled copy). Keep only settled lines — drop every line containing a tag
(`<`), then drop neighbour duplicates:
```bash
grep -v -- '-->' "$vtt" \
 | grep -vE '^(WEBVTT|Kind:|Language:)' \
 | grep -v '<' \
 | sed 's/[[:space:]]*$//' | awk 'NF' | awk '$0!=last{print;last=$0}' > clean_<ID>.txt
```
Rough size: a ~4h interview → ~30–50k words; a 30-min solo → ~13k.

### 5. One worker per transcript
Dispatch one subagent per `clean_<ID>.txt` (parallel where the host
supports it, otherwise sequential). Give each: the file path + episode meta
(guest, solo?, orientation) and the ONE extraction target. Each returns
compact structured markdown (a score/label + 3–6 quoted-or-paraphrased
beats). A cheap model tier is enough — the transcript reading is the cost,
not the reasoning. **The transcript stays in the worker's context, never the
main thread.**

### 6. Synthesize
Build the overall picture from the summaries: a comparison table + the
cross-episode findings, each tied to concrete beats.

### 7. Store
Write the synthesis as a knowledge-layer note per `storage-contract.md`
(derive the path from `.methodik-capabilities.json`, never hardcode) and run
the consumer's `indexer_command` afterwards.

## Hard rules (the expensive lessons)

- **Bot-bypass is mandatory** — without the `player_client` override, pulls
  die after ~3 requests.
- **Transcripts only ever enter subagent contexts**, never the main thread —
  that is the whole cost saving.
- **Auto-subs have no speaker labels.** In a 2-person interview the worker
  must split host vs. guest by content (host = short questions/reactions;
  guest = long monologues) and is fallible. **Solo episodes are the cleanest
  source of a person's own stance.** Flag every single-speaker claim as
  "attribution inferred", never as proven.
- **Expect ASR errors** on proper nouns — verify any load-bearing name/quote.

## Rigor gates (do not skip — these are where deep-dives go wrong)

- **Base-rate control:** if you sampled only the striking/political episodes,
  say so, and do NOT generalise the finding to the whole channel — a
  characterisation of the sample is not a characterisation of the format.
  Report what fraction of total output the sample represents.
- **Watch for a leading question.** If the request presupposes the
  conclusion, guard against confirmation bias — actively look for
  disconfirming beats and report them.
- **Calibrate language:** "in the selected episodes, plausibly X" beats
  "the channel is X". Reserve "proven" for what the transcripts actually
  show; "stated"/"observed" ≠ "measured effect".
- **Optional cross-model review** for high-stakes / contested findings: hand
  the synthesis + a few transcripts to a second model to check attribution,
  overclaims, and cherry-picking before shipping.

## Cost

Pulling/cleaning is near-free (bash only). The spend is N worker contexts ×
transcript size; a cheap model tier keeps it modest. Never read a full
transcript into the orchestrating context.
