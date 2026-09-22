---
id: wm-w98jug
type: task
title: Dev on-call 2026-09-22..09-29 — work the open PagerDuty incident set (20 open)
status: active
priority: p1
size: ~1 day
due: 2026-09-29
tags: [oncall, pagerduty]
created: 2026-09-22T17:26:27Z
updated: 2026-09-22T17:26:44Z
source: claude-code
---

## Log
- 2026-09-22T17:26Z [claude-code] Baseline from PD REST API 2026-09-22T17:15Z: 20 open (13 triggered all auto-assigned to Abhishek as efp-coder dev-primary until 2026-09-29T13:30Z; 7 acked — 6 Nakula, 1 Rishabh/devops). All P3/low. 679 incidents resolved 09-08..09-22 (~45/day) — the open set is the tail of a high-volume recurring stream, not 20 distinct problems. 8 of the 20 are duplicate pairs: dumbledore fires generate_datastores_ubuntu AND populate_efp_stats_ubuntu as separate incidents for the same root failure, same second. Real distinct problems open: ~12.
