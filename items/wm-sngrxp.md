---
id: wm-sngrxp
type: next
title: Create 2 new NorthPond Linear projects + link 4 orphaned issues
status: open
priority: medium
size: 15m
tags: [linear, northpond]
created: 2026-08-19T11:53:20Z
updated: 2026-08-19T13:00:04Z
source: claude-code
---

Decided 2026-08-19 (abhishek) — not reopening any old project. Two new
projects to create, plus links to two existing ones. All manual — agent is
not touching Linear.

CREATE:
- "NorthPond Nelnet Migration" (or similar name) -> attach DEV-1481
  (Ingest Oliv's Nelnet servicer files; currently In Review, no project,
  7 PRs already stacked on it)
- "NorthPond EDGEX / ANL Enhancements" (or similar name) -> attach
  DEV-1445 (Retarget NorthPond at_orig cashflows to Oliv's ANL, Done
  2026-07-27) and DEV-1468 (Ingest Oliv issuance_v2 / carry ANL into
  silver.predictions, Done 2026-07-24). Open tail of this work is already
  tracked separately: wm-btu784, wm-vye9hn, wm-etzegu.

LINK to existing projects:
- "Predictions Ingestion" (cross-platform, Nakula, target 2026-08-20) ->
  DEV-1498 (Setup NorthPond CMOP/BEP), DEV-1499 (Setup OpenRoad CMOP/BEP).
  Scope match confirmed against the project description.
- "Demise datastores" (cross-platform, Scott Morgan) -> DEV-1486 (Deprecate
  OpenRoad Datastores, Done 2026-08-03). NorthPond's own datastore
  deprecation (DEV-1450) is already done and correctly filed under
  "Northpond Data Ingestion" — no action needed there.

DEFERRED, not decided: DEV-1474 (purchase tape SFTP path) and DEV-1509
(rename experimental Northpond fund) have nowhere confirmed to go yet.

New projects should get a lead/priority/target date/definition-of-done per
~/notes/areas/linear/conventions.md hygiene checklist when created.

OpenRoad side of this sweep (DEV-1499 aside) deliberately not started —
abhishek wants NorthPond settled first.
