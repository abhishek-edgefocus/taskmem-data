---
id: wm-6k56mk
type: task
title: Disable the dpx ~/tasks crontab (unattended claude runs + automated DMs, against policy)
status: inbox
due: 2026-07-16
people: [Abhishek]
tags: [taskmem]
created: 2026-07-15T15:08:25Z
updated: 2026-07-15T15:08:25Z
source: intake-review
---

Intake sweep 2026-07-15 evening: the dpx ~/tasks agent-brief cron is still live — it sent an automated 'Morning brief — Wed Jul 15' Slack self-DM today (with stale dpx #ids), and Abhishek told Abhijeet it's 'still not working properly'. This violates the no-unattended-claude-runs policy and risks split-brain with taskmem (now canonical; dpx items were imported 2026-07-15).

Fix on dpx (server is user-managed, agents must not change it): crontab -e, delete the '# >>> task-system >>>' block. Optionally archive ~/tasks.
