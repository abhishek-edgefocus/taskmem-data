---
id: wm-kpyq3c
type: decision
title: Work memory v1: markdown files + git + generic CLI
status: open
tags: [taskmem]
created: 2026-07-14T14:20:46Z
updated: 2026-07-15T18:09:33Z
source: bootstrap
---

Chose flat-frontmatter markdown per item, git for history, one generic zero-dependency CLI (taskmem), and prose contracts (SCHEMA.md/AGENTS.md) for all business logic. Full rationale in README.md. Revisit storage (SQLite cache) only if scale demands it.

## Log
- 2026-07-15T13:33Z [claude-code] renamed tool workmem -> taskmem; brand is replaceable (see README 'Renaming the tool'), wm- ids and WM_* env vars are stable engine identifiers
- 2026-07-15T14:05Z [claude-code] ported from dpx ~/tasks tool: session-start context injection, DASHBOARD.md, install.sh, agent-brief, size/scheduled/waiting_on/nudge/refs fields, inbox/next/someday statuses, next-step rule. Kept taskmem philosophy: views are deterministic, judgment stays in prompts. Rejected: sequential ids, projects.yaml, plan-in-code.
- 2026-07-15T14:39Z [claude-code] ported dpx notification system: review agents send ONE structured Slack DM (Today/Nudge/Flags, only to Abhishek U0B0XRSGV2A), tm notify as desktop/fallback; Linear read-only reconciliation in review prompts. Test DM delivered.
- 2026-07-15T15:03Z [claude-code] user policy correction: cron must never invoke claude; crontab now sends reminder notifications (daily 08:30, intake 14:00, weekly Fri 17:00) and user runs bin/agent-brief manually. Slack DM briefs restored since every run is human-triggered. Deterministic cron (sync, dashboard) unchanged.
- 2026-07-15T18:09Z [claude-code] agent-behavior eval round 1: 6 sandboxed scenarios, graded 9.30/10 overall; 5 protocol fixes shipped in AGENTS.md (commit 8dba059). Round-2 validation on hold per Abhishek, tracked separately.
