---
id: wm-bvqkhh
type: task
title: Finalize DEV-1331 OpenRoad predictions datastore-comparison notebook
status: next
priority: p1
size: s
due: 2026-07-17
tags: [openroad]
links: [parent:wm-su6q4d]
refs: [notebook=http://dexterplus.edgefocus.net:12053/notebooks/repos/efp/slop/dev1331_openroad_predictions_datastore_comparison.ipynb, DEV-1331=https://linear.app/edge-focus/issue/DEV-1331]
created: 2026-07-14
updated: 2026-07-17T12:53:08Z
source: dpx-tasks #13
label: OpenRoad predictions notebook
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #13
- 2026-07-16T19:05Z [claude-code] Linear check (2026-07-17): DEV-1331 'Ingest and validate predictions' has NO issue-level due date, but its project milestone 'Validate predictions' (OpenRoad Data Ingestion) targets 2026-07-17 = TODAY, at 25% progress. DEV-1331 is the ONLY issue in that milestone, so the milestone IS this ticket. Status 'In Review' since 2026-07-01 (16 days), assignee Abhishek, PR #5709 attached. Prior milestone 'Validate positions' hit 100% on time (2026-07-08); next milestone 'Deprecate datastores' targets 2026-07-22 at 0%. Project target 2026-07-22, lead Abhijeet. Set due=2026-07-17 accordingly.
- 2026-07-17T12:53Z [claude-code] Re-verified DEV-1331 notebook against live dev data (2026-07-17). Notebook itself is COMPLETE: 37 cells, all 24 code cells executed run#1-24, no errors, summary table present. Jupyter servers on dpx alive: 12053 (conda) + 22053 (venv), both up since Jun 11. PR #5709 merged 2026-07-02. Abhijeet commented 2026-07-13 'is this good to close?' - still unanswered. Live re-check vs notebook's Jul-2 conclusions: (1) EFP_ID convention row is now STALE - DEV-1393 (merged Jul 8) switched openroad_api_predictions.py to LOAN_ID crosswalk; predictions now join legacy datastore AND positions 35/35 directly, so notebook Section 4 crosswalk is obsolete machinery. (2) MOB_ACCOUNTING_DATE +1 day vs legacy pred datastore: STILL HOLDS 35/35. (3) RECOVERY_FRAC/SERVICING_FEE NULL: STILL HOLDS 0/2507. NEW ISSUE FOUND: predictions.mob_accounting_date disagrees with positions.mob_accounting_date by 14-15 days on all 35 loans, despite predictions being designed to derive mob from positions (commit 6d940e9cd). silver.predictions last_altered Jul-8 09:25 PT vs silver.positions Jul-16 07:20 PT - predictions appears STALE w.r.t. the DEV-1393-corrected positions. Recommend rebuilding predictions in dev + re-running notebook before closing.
