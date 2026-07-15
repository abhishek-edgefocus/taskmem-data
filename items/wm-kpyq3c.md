---
id: wm-kpyq3c
type: decision
title: Work memory v1: markdown files + git + generic CLI
status: open
tags: [taskmem]
created: 2026-07-14T14:20:46Z
updated: 2026-07-15T14:05:20Z
source: bootstrap
---

Chose flat-frontmatter markdown per item, git for history, one generic zero-dependency CLI (taskmem), and prose contracts (SCHEMA.md/AGENTS.md) for all business logic. Full rationale in README.md. Revisit storage (SQLite cache) only if scale demands it.

## Log
- 2026-07-15T13:33Z [claude-code] renamed tool workmem -> taskmem; brand is replaceable (see README 'Renaming the tool'), wm- ids and WM_* env vars are stable engine identifiers
- 2026-07-15T14:05Z [claude-code] ported from dpx ~/tasks tool: session-start context injection, DASHBOARD.md, install.sh, agent-brief, size/scheduled/waiting_on/nudge/refs fields, inbox/next/someday statuses, next-step rule. Kept taskmem philosophy: views are deterministic, judgment stays in prompts. Rejected: sequential ids, projects.yaml, plan-in-code.
