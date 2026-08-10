---
id: wm-qtjmcv
type: task
title: DEV-1509: rename the northpond 'experimental' fund to northpond_balancesheet
status: open
priority: p3
size: s
people: [Sean]
tags: [northpond]
links: [relates:wm-7qqeke]
refs: [DEV-1509=https://linear.app/edge-focus/issue/DEV-1509/rename-experimental-northpond-fund]
created: 2026-08-10T14:53:27Z
updated: 2026-08-10T14:53:28Z
source: claude-code
---

## Log
- 2026-08-10T14:53Z [claude-code] Filed by Sean Mills 2026-08-05, moved Backlog -> Todo 2026-08-10 14:49Z, assigned Abhishek, No priority, no due date. Ticket text: 'This should probably say northpond_balancesheet or something for clarity. Also, should confirm these are showing up where relevant such as MOB curves.'

RELATED TO BUT NOT THE SAME AS [[wm-7qqeke]] (the FUND_WITH_PURCHASE_TAPE_EXPR hardcoded-efhyf fix). Same file and adjacent lines — FUNDS.EXPERIMENTAL is NORTHPOND_ACCOUNT_FUND_MAP['ef_northpond'] at northpond/constants.py:16, the efhyf hardcode is at :50 — so the two will conflict textually if done in parallel, but they are independent fixes. wm-7qqeke is Tuesday-blocking (first live EDGEX purchase file 2026-08-11); DEV-1509 is not.

BLAST RADIUS (verified on origin/master d1e9c461c): FUNDS.EXPERIMENTAL is northpond-only — just 3 references, all in northpond files (northpond/constants.py:16, northpond/transfers.py:143 TAPE_FROM_FUND, northpond/transfers.py:184 TAPE_FUND). The enum member itself sits in the SHARED edgefocus/transformations/silver/statement_rows/constants.py:41, but no other platform consumes it, so the shared-file edit is a single enum value with no cross-platform reach.

THE REAL COST IS DATA, NOT CODE — the literal string 'experimental' is already persisted in prod (2026-08-10): silver.northpond_stmt_positions 155,812 rows; silver.northpond_stmt_transactions 38,878 rows; silver.positions (platform=northpond) 155,823 rows. ~350k rows total. Changing the enum VALUE only affects rows written after the change, so without a backfill the same fund exists under two names and every downstream group-by splits. Sean's 'confirm these are showing up where relevant such as MOB curves' is exactly that concern. Decide up front: rename value + backfill existing rows, or keep the stored value and rename only the display.

NOTE the efhyf side is unaffected by this ticket: silver.northpond_stmt_positions has 179,093 efhyf rows and northpond_stmt_transactions 102,939.
