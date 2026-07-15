---
id: wm-jpxt8v
type: idea
title: Revisit: restructure into ~/brain monorepo (taskmem/ + notes/ + context/)
status: someday
tags: [taskmem]
created: 2026-07-15T15:37:16Z
updated: 2026-07-15T15:37:16Z
source: claude-code
---

Deferred on 2026-07-15 — attempted, rolled back cleanly at Abhishek's request; taskmem stays independent at ~/taskmem for now. The dry run proved the plan works, so this is cheap to redo.

## Next steps (the proven sequence)
1. Patch bin/taskmem for subfolder mode: in_repo() -> 'git rev-parse --git-dir' (repo root may be a parent), and commit() -> 'git add -A -- .' so tm never sweeps sibling folders' edits.
2. Same rev-parse fix in bin/dashboard's commit check; install.sh: rev-parse instead of [ -d .git ], and make the hooks-merge REPLACE stale session-context paths (repo move) rather than only append.
3. mv ~/taskmem ~/brain && cd ~/brain && mkdir taskmem notes context && git mv <all top-level> taskmem/ && mv .logs taskmem/ (history survives via --follow).
4. sed docs '~/taskmem' -> '~/brain/taskmem'; hand-fix: clone targets (clone ~/brain), multi-host remote (repo name brain), Renaming section (git -C ~/brain mv ...).
5. Seed ~/brain/README.md + context/README.md + notes/README.md; add 'wider brain repo' section to AGENTS.md (consult context/ before related work; notes/ for long-form; atomic decisions stay items).
6. Commit, rerun install.sh --cron (refreshes symlinks, hook paths, crontab paths), update ~/.claude/CLAUDE.md paths, update wm-c4vhst (remote becomes github.com/<user>/brain).

## Links
- Storage discussion + rationale: this item's Log; decision item wm-kpyq3c
- Remote task it interacts with: wm-c4vhst (if the remote is created first as 'taskmem', the repo can still be renamed to 'brain' on GitHub later)
