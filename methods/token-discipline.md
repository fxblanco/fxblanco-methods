# Token discipline

**Applicability:** any host running unattended or long-running sessions, or with a real token/cost budget to manage. A one-shot interactive session with no cost pressure can skip this.

1. **Discovery before read.** For any question about a topic/area, consult a router/index first (whatever the host has: a tag index, a directory README, a knowledge graph). Then read 2–5 specific files. Never blanket-scan everything.
2. **Known sections → offset/limit.** If you already know roughly where the relevant content lives in a file, read that slice, not the whole file.
3. **Re-read only on content change.** If a file hasn't changed since you last read it in this session, work from what you already have. Don't re-load the same file dozens of times.
4. **When genuinely unsure, prefer a second targeted read over a wrong answer.** Quality beats a small token saving — but the second read should target a different slice, not repeat the first.
5. **Heavy reads (audits, cross-repo sweeps, anything expected to cost a lot of context) go to a subagent** with its own context window, not the main session.
