# Retrieval order

**Applicability:** the algorithm is universal; the concrete stages are host-specific and come from the consumer's `.methodik-capabilities.json` (`retrieval_stages`, an ordered list — e.g. `["memory","graph","state","sources","web"]` for a host with all of that infrastructure, or just `["sources","web"]` for a host with none of it).

**Algorithm:** for any factual question, try the richest available stage first, in the order the host declares, and only fall through to the next stage if the current one has nothing. Never skip straight to a weaker stage (e.g. guessing, or web search) when a stronger one (e.g. the host's own live state) hasn't been checked yet.

This is `core/METHOD.md`'s evidence-first law made operational: it's not enough to eventually find a source — you have to check the stages that are most likely to have the *authoritative, current* answer before falling back to ones that are merely *plausible*. A cached snapshot from days ago loses to a live state query; a live state query loses to nothing if there simply isn't one to check.
