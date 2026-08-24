---
id: wm-duhj7d
type: bug
title: Anchored + HappyMoney positions dropout spike to ~80-89% of book starting 2026-08-18
status: open
priority: high
tags: [anchored, happymoney, positions, dropout, on-call]
created: 2026-08-19T16:47:38Z
updated: 2026-08-24T12:33:43Z
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

## Log
- 2026-08-24T12:33Z [claude-code] 2026-08-24 openroad investigation reframes this item. The daily #dropout-loans-info report flagged openroad +15/15 on the 08-22 and 08-23 posts; both have since self-healed (silver.positions openroad = 35/35 real rows on 08-20..08-23, 0 dropout). ROOT CAUSE for openroad is Foursight delivery slip + report timing, not a matching break: the loan tape for as_of D normally lands 03:37 PDT on D+1 and the dropout report runs 09:03 PDT, so D-1 is real by report time. Foursight skipped 2026-08-21 entirely (no file loaded that day), putting the feed a day behind through 08-23 (as_of 08-20 loaded 08-22, 08-21 loaded 08-23, 08-22+08-23 both loaded 08-24, i.e. now caught up). While the feed was a day behind, the report's target date was still autofilled -> the ENTIRE live openroad book showed as dropout. 15 = openroad's whole current book (35 loans = 15 current + 14 fully_paid + 6 charged_off). RELEVANT TO THIS ITEM: anchored rides the identical Foursight feed (same loader, same timestamps, verified in bronze.statement_files) and its 271 is likewise anchored's entire non-terminal book of 349; anchored 2026-08-23 in silver.positions is 347 real / 0 dropout. So the anchored half of this item is very likely the same delivery-lag artifact rather than a join/format break. happymoney is a different vendor and was NOT checked -- that half still stands open.
