---
id: wm-cgftbn
type: task
title: Map FULLY_PAID_DATE for NorthPond after PR #6008
status: active
priority: p2
size: s
people: [Abhijeet]
tags: [northpond, platform-data-owners]
links: [relates:wm-j523sq, parent:wm-3sxcre]
refs: [DEV-1516=https://linear.app/edge-focus/issue/DEV-1516/add-fully-paid-date-mapping-for-northpond]
created: 2026-07-29T18:10:01Z
updated: 2026-08-21T14:05:17Z
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
- 2026-08-20T12:20Z [claude-code] Dagster-verified in DEV_ABHISHEK (2026-08-20), which closes the 'no Dagster run URL' gap on PR #6401.

Setup: did NOT reuse ~/repos or ~/repos-2 (both hold other agents' dev-1481 branches, and repos-2 backs the long-running :13054 server). Started a per-workspace server instead, matching how oliv-exp (:13077) and openroad-gold (:13078) already run — mine is :13079 from ~/claude-ws/dev-1516/efp, DAGSTER_HOME=~/claude-ws/dev-1516/dagster_home. Confirmed 13054/13077/13078 unaffected.

Two gotchas for next time: the dagster CLI needs PYTHONPATH=<ws>/efp:<ws>/efp/lib or it dies with 'No module named efp' (the lib/ package is not installed into the venv), and a plain materialize is a no-op because the DEV watermarks are already caught up ('0 deleted, 0 inserted, Dates processed: none'). Force a rebuild with --config-json '{"ops":{"northpond_positions":{"config":{"as_of_date":"YYYY-MM-DD"}}}}'.

Run 9e89e5a5-7bac-43dc-baba-bc1fbec4fc61, RUN_SUCCESS in 11m19s, 1,164 deleted / 1,164 inserted for as_of 2026-08-17.

Result in DEV_ABHISHEK.SILVER.POSITIONS: on the rebuilt date 76/76 fully_paid rows dated, 0 leaked, 0 in the future; the untouched neighbouring dates 2026-08-15 and 08-16 still show 76 fully_paid and 0 dated, which is a clean before/after within one table. Flappers all take the first payoff (OLV12562742 -> 2025-06-18), both override loans and both Nelnet loans dated. 76 rather than prod's 77 because dev source data stops at 2026-08-17.
- 2026-08-20T18:50Z [claude-code] 2026-08-21 00:18 IST: PR #6401 (DEV-1516 NP FULLY_PAID_DATE) posted for review in #platform-data-owners.
- 2026-08-21T11:48Z [pr-manager] PR #6401 (DEV-1516, FULLY_PAID_DATE for NorthPond) merged 2026-08-21 11:10.
- 2026-08-21T14:05Z [linear-agent] DEV-1516 shipped: PR #6401 merged + approved 2026-08-21. Live in prod via statements_northpond run 40935dab (northpond_positions SUCCESS). Linear still reads In Review — close-out comment drafted and handed to Abhishek to paste (he applies Linear changes himself).
