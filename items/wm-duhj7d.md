---
id: wm-duhj7d
type: bug
title: Anchored + HappyMoney positions dropout spike to ~80-89% of book starting 2026-08-18
status: open
priority: high
tags: [anchored, happymoney, positions, dropout, on-call]
created: 2026-08-19T16:47:38Z
updated: 2026-08-19T16:47:38Z
source: claude-code
---

Found while investigating the "Missing Platform Data" Grafana dashboard
(frdnx8m) at the user's request.

## What happened
On 2026-08-18 both anchored and happymoney silver.positions went from 0
dropout loans to nearly the entire book autofilled in a single day:

| platform   | as_of_date | total_loans | dropout_loans | % |
|---|---|---|---|---|
| anchored   | 2026-08-18 | 349   | 271   | 78% |
| anchored   | 2026-08-19 | 349   | 271   | 78% (still, not self-healed) |
| happymoney | 2026-08-18 | 15937 | 14117 | 89% |

Both were flat at 0 dropout every day for at least the prior 3 weeks
(checked back to 2026-07-29), so this is a sudden onset, not a slow
accumulation.

## What it's NOT
gold.statement_files_missing (the raw-file-arrival check) has no rows for
anchored or happymoney, so the daily statement files themselves arrived —
this looks like a matching/processing break (loan_id join, format change,
etc. in the silver.positions autofill path), not a missing-file problem.
Contrast with northpond/intex, which DO show up in statement_files_missing
for unrelated reasons already tracked elsewhere.

## Not yet investigated
- Root cause (which commit/deploy, what changed in the 08-17->08-18
  statement for either platform)
- Whether this is one shared cause (two platforms same day) or coincidence
- Whether gold-layer metrics (positions_daily, cashflows) downstream of
  silver.positions are now wrong for these platforms

## Where I looked
PROD.gold.positions_autofilled_daily, PROD.silver.positions (row/dropout
counts by as_of_date), PROD.gold.statement_files_missing — all queried live
via edgefocus.data_warehouse.snowflake from ~/repos/efp on dpx.
