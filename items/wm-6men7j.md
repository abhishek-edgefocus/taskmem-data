---
id: wm-6men7j
type: task
title: Enable cross-device task sync via a private data repo
status: done
tags: [taskmem]
links: [follows:wm-c4vhst]
created: 2026-07-15T17:38:35Z
updated: 2026-07-16T10:35:40Z
source: claude-code
---

The private repo github.com/abhishek-edgefocus/taskmem currently holds ONLY infrastructure (task-free 'infra' snapshot as main). Abhishek explicitly excluded task content for now. When he decides to sync tasks:

## Next steps
1. cd ~/taskmem && git remote add origin https://github.com/abhishek-edgefocus/taskmem.git
2. git push -f origin main   # replaces infra-only main with full history (contains all task data — this is the consent moment)
3. tm sync                   # from here the 15-min autosync keeps it converged
4. Other machines: follow README 'Setup on a fresh machine' (clone + install.sh).

Note: adding the remote WITHOUT the force-push leaves autosync failing on unrelated histories — do steps 1-3 together.

## Links
- Repo: https://github.com/abhishek-edgefocus/taskmem
- Predecessor: wm-c4vhst (repo creation, done 2026-07-15)

## Log
- 2026-07-16T10:35Z [device2] sync test from a fresh clone (device 2)
- 2026-07-16T10:35Z [claude-code] done, with a better design than planned: instead of pushing task data over the shared tool repo, created private github.com/abhishek-edgefocus/taskmem-data and wired it as origin via the new install.sh --remote flag. Verified: seed push, round-trip sync, fresh clone (33 items, no config.env leak), two-way sync from a second clone. The 15-min autosync cron now converges devices automatically; new machine = clone taskmem-data + install.sh.
