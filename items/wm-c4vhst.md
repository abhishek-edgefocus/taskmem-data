---
id: wm-c4vhst
type: task
title: Create private GitHub repo and connect taskmem remote
status: open
priority: p2
due: 2026-07-17
tags: [taskmem]
links: [relates:wm-kpyq3c]
created: 2026-07-15T13:53:45Z
updated: 2026-07-15T13:53:45Z
source: claude-code
---

One-time step to enable cross-host/agent sync (protocol is already live; verified against a simulated remote 2026-07-15).

1. Create a PRIVATE repo under the personal profile: https://github.com/new (name: taskmem), or 'gh repo create taskmem --private' if gh gets installed.
2. cd ~/taskmem && git remote add origin git@github.com:<user>/taskmem.git && tm sync

Other hosts then follow README 'Setup on a fresh machine'. Optional: the */15min autosync cron line in README 'Multi-host'.
