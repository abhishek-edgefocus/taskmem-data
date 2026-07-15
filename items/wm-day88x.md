---
id: wm-day88x
type: task
title: Run round-2 validation eval for the AGENTS.md optimizations (on hold per Abhishek)
status: someday
tags: [taskmem]
created: 2026-07-15T18:09:33Z
updated: 2026-07-15T18:09:33Z
source: claude-code
---

Round 1 of the agent-behavior eval ran 2026-07-15 (6 scenarios, sandboxed; overall 9.30/10) and produced 5 AGENTS.md fixes, applied in commit 8dba059: active-vs-waiting decision test, any-mutation-counts-as-touch, reread-after-write, mandatory ref links + plain language in replies, observable sync mention, no scratch files in repo. Round 2 (same scenarios, fresh sandboxes, A/B against round-1 scores) was prepared but Abhishek asked to hold new sub-agent rounds.

## Next steps
1. When approved: rebuild 6 sandboxes from current ~/taskmem (cp -R; baseline = HEAD), regenerate digest.
2. Re-launch the saved workflow FRESH (not resume): script at ~/.claude/projects/-Users-abhishek/088d1f15-3a94-4724-af92-ec8b8c72ceb9/workflows/scripts/taskmem-agent-eval-wf_8f3aca2f-918.js with updated baseline in args.
3. Compare per-dimension scores vs round 1 (capture 9.6 / completion 9.8 / dedup 9.8 / blocked 9.4 / triage 8.6 / session-end 8.6); expect triage bodies (7) and session-end updates (7) to move most.
4. Safety rails during any round: chmod -R a-w ~/taskmem/items, remove tm/taskmem symlinks, WM_DIR-jailed sandboxes; RESTORE after.

## Links
- Round-1 full results: /private/tmp/claude-501/-Users-abhishek/088d1f15-3a94-4724-af92-ec8b8c72ceb9/tasks/wllmkpdmm.output (session scratchpad — copy out if it should survive)
- Optimization commit: 8dba059 in ~/taskmem
