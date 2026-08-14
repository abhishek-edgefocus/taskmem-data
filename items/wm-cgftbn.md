---
id: wm-cgftbn
type: task
title: Map FULLY_PAID_DATE for NorthPond after PR #6008
status: next
priority: p2
size: s
people: [Abhijeet]
tags: [northpond, platform-data-owners]
links: [relates:wm-j523sq, parent:wm-3sxcre]
created: 2026-07-29T18:10:01Z
updated: 2026-08-14T19:57:11Z
source: claude-code
---

Abhijeet merged https://github.com/edgefocus/efp/pull/6008 on 2026-07-29 22:38 IST and asked in #platform-data-owners (C0B6M0AQKB5, ts 1785344915.911469) that each platform owner add the FULLY_PAID_DATE mapping. The other 8 new silver.positions columns (SALE_DATE, PRIOR_*, ACCRUED_INTEREST_PRICE_FRAC) are populated by shared code in positions_utils.py lines 382-390 and need nothing per-platform.

Verified 2026-07-29 on origin/master: NO platform has mapped FULLY_PAID_DATE yet — the only references are the ColumnDefinition in positions_constants.py:899 and terraform/snowflake/silver_positions.tf:832. We would be first.

The work (all in edgefocus/transformations/silver/statement_rows/northpond/positions.py):
1. The Oliv tape has NO payoff-date field. Flattened every RAW_RECORD key on the 2026-07-29 bronze positions rows: the only status/paid-ish keys are LoanState, LoanStatus, BankruptcyStatus, CumulPrincipalPmtPrepaidLTD. So it must be derived.
2. Legacy semantic to match (datastore_closed_positions.py:70): fully_paid_date = as_of_date on the row where status became fully_paid. Matches the new column comment ('first date STATUS became fully_paid').
3. Must follow the Prosper precedent (prosper/positions.py:260-266 RESOLVED_CHARGE_OFF_DATE): compute the window inside a subquery over the UN-date-filtered silver.northpond_stmt_positions, i.e. MIN(CASE WHEN <status> = 'fully_paid' THEN p.AS_OF_DATE END) OVER (PARTITION BY p.LOANNUMBER), then reference it in COLUMN_MAPPING. A naive window in COLUMN_MAPPING returns today's date on incremental runs because only the processing window is in scope.
4. Use the mapped status (generate_status_mapping), not raw LOANSTATUS='PaidOff' — the two NORTHPOND_PAID_OFF_OVERRIDE_LOANS are forced from ChargedOff to fully_paid.

Prod sizing / validation baseline (2026-07-29): 73 fully_paid northpond loans, all 73 present in silver.northpond_stmt_positions; 72/73 agree between MIN(as_of) on raw LoanStatus='PaidOff' and MIN(as_of) on silver.positions STATUS='fully_paid'. The single disagreement is an override loan, which confirms point 4. Date range 2024-12-19 to 2026-07-23.
