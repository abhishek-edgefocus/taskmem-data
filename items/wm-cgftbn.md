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
refs: [DEV-1516=https://linear.app/edge-focus/issue/DEV-1516/add-fully-paid-date-mapping-for-northpond]
created: 2026-07-29T18:10:01Z
updated: 2026-08-20T11:53:16Z
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

## Log
- 2026-08-20T10:57Z [claude-code] Implemented on branch abhishek/dev-1516-fully-paid-date in ~/claude-ws/dev-1516/efp (commit 4aa299d22, not yet pushed).

Landscape had moved since the 2026-07-29 analysis: prosper, anchored, sofi, marlette, figure and innovate all map FULLY_PAID_DATE now, and NorthPond gained the Nelnet+FCC union (PR #6277), so the derivation runs over NORTHPOND_POSITIONS_UNION rather than the bare FCC table.

Key finding that changed the design: NorthPond takes MIN, not the LAG/LAST_VALUE current-run pattern the sibling platforms use. 7 of the 77 ever-fully-paid loans flap — they report PaidOff, then Current again for a day or two with CURRENTPRINCIPAL already 0, then flip back. OLV12562742 does it six times between 2025-06-18 and 2025-11-27; the run pattern would date that payoff 162 days late. Innovate maps it the same way for the same reason.

The legacy datastore is NOT a usable oracle here: it stamps one fully_paid row per transition and consumers keep the LAST, which reads 2026-08-12 for loans that truly paid off in 2025 (a datastore-side artifact — the tape is continuously PaidOff through that date). Only 35/77 agree with the datastore's last value; 74/77 agree with its FIRST value, which is what we now produce.

Validation (2026-08-19): built the transform from master and from the branch into DEV_ABHISHEK and diffed — 1,198 rows each, identical on all 144 other columns (only UPDATED_AT moves), FULLY_PAID_DATE 0 -> 77. Full history: 19,628/19,628 fully_paid rows dated across 77 loans, 0 set on non-fully-paid rows, 0 in the future. Both Nelnet payoffs (OLV12563339, OLV12563356 -> 2026-08-01) and both override loans dated correctly.

The one real disagreement, OLV12562729, is correct-by-construction: balance hits 0 on 2026-06-17 but the servicer only reports PaidOff on 2026-06-18, and our date follows STATUS.

Left in DEV_ABHISHEK.PUBLIC for review: NP_POS_DEV1516_BASE and NP_POS_DEV1516_NEW.
- 2026-08-20T11:53Z [claude-code] PR raised: https://github.com/edgefocus/efp/pull/6401 (branch abhishek/dev-1516-fully-paid-date, +214/-0, 2 files). Pushed from ~/claude-ws/dev-1516/efp at his explicit instruction, overriding the usual no-agent-initiated-writes handoff.

Correction to the earlier log entry: the flapping affects 7 loans, not 8, under the MAPPED status. The raw-LOANSTATUS='PaidOff' query returns 8 because it includes OLV12562566, an override loan whose ChargedOff rows map to fully_paid from its first row — so it does not flap once the status mapping is applied. PR body states 7.

PR body lives at ~/claude-ws/dev-1516/notes/PR_BODY.md on dpx; proof queries at ~/claude-ws/dev-1516/notes/proof.sql. Screenshots NOT yet attached — the body carries the results as markdown tables and says screenshots are being attached, so that is an open loose end on the PR. Also no Dagster run URL: validation was a direct CREATE TABLE AS of the transform's generated SQL into DEV_ABHISHEK, not a Dagster materialize.
