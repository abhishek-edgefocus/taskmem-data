---
id: wm-skvqac
type: task
title: Write openroad_verified.py and register the by-design OpenRoad positions differences
status: next
size: s
people: [Frank]
tags: [openroad, datastores, data-quality]
links: [follows:wm-hecgua, parent:wm-jr5bup]
created: 2026-08-14T14:55:14Z
updated: 2026-08-24T13:26:18Z
source: claude-code
effort: <1h
label: openroad_verified.py
---

Split out of [[wm-hecgua]] on 2026-08-14, because that item held two things with opposite urgency:
salvaging the untracked docs is at risk of being lost and should happen today, while writing the
registration file must NOT happen yet. Keeping them in one item meant the ordering could not be
expressed and the urgent half was hidden behind the blocked half.

WHAT THIS IS. `edgefocus/transformations/silver/comparison/` on master carries verified-differences
files for happymoney, innovate, marlette, northpond, sofi, upgrade and upstart — but not openroad.
Frank asked about exactly this on 2026-08-12, inline on Scott's "Datastore Retirement — Open
Questions & Linear Coverage Gaps" doc: "for prosper, anchored and openroad, @sanjali and @abhishek
is this right? We don't have the verified-differences file? Was that a miss?" For OpenRoad the
validation itself was not missed — full-history compare over 1,079 dates, a 16-row mismatch table,
four issues fixed and merged in PR #5807 on 2026-07-09. Only the registration file was never
written.

WHY IT IS BLOCKED, not just queued. In prod today `silver.positions` for openroad holds 280 rows /
35 loans / 8 dates ending 2026-07-06, and `gold.positions_comparison_daily` reports COMMON_COUNT=0
against the legacy datastore on 141 of 142 dates. Writing the file now would register by-design
differences against a table that is stale by a month and short by roughly 1,070 dates — it would
paper over the dead silver chain rather than answer Frank. The silver chain has to be running and
backfilled before the file means anything.

WHAT GOES IN IT (from the untracked doc's own status list): mismatches #6 pool_id, #7 zip_code,
#8 apr_at_purchase, #10 pti, #11 the 16-loan offer-join family, #15 is_joint — plus #2/#3
credit_score / VANTAGE4 if the model_requests ingestion ([[wm-bpmxnb]]) is deferred rather than
built.

## Next steps
- Wait for the silver chain to be alive and backfilled (the two items this is blocked on).
- Then write the file modelled on `northpond_verified.py`, and reply to Frank on the Linear doc
  pointing at PR #5807 as the evidence the validation was done.

## Links
- Frank's question — https://linear.app/edge-focus/document/datastore-retirement-open-questions-and-linear-coverage-gaps-2026-08-ed6197316dcf
- The validation PR — https://github.com/edgefocus/efp/pull/5807
- Sibling doc that this one is modelled on: [[wm-6zdqhy]]
- Salvage half: [[wm-hecgua]]

## Log
- 2026-08-24T12:33Z [claude-code] 2026-08-24: UNBLOCKED. This item was waiting on two things — the OpenRoad silver chain being alive, and the backfill. Both landed 08-21/08-22: openroad_statement_sensor is RUNNING, statements_openroad is 15/15 green, and the bronze backfill took silver.openroad_stmt_positions from 52 days to 1,127 days (2023-07-20 -> 2026-08-19). Abhishek named this his #1 for today (DEV-1638, verified differences).
- 2026-08-24T13:26Z [claude-code] DEV-1638 WRITTEN 2026-08-24, committed 78b28d923 on abhishek/dev-1638-openroad-verified in ~/claude-ws/dev-1638/efp (NOT pushed - waiting on Abhishek). openroad_verified.py registers 19 columns; verified_differences.py gets the six-line import block that every platform needs (the only shared-file edit, additive, cannot affect another platform).

REGISTERED: pool_id, apr_at_purchase, ef_score (datastore populates 0/35 on every date);
application_id, income(+band), dti_preloan_purch(+band), employment_length_days(+band) (the
16-loan gateway-offer dedup family, 18/18 exact agreement where both populate); credit_score,
credit_score_at_purchase, credit_score_last_update_date; installment(+band), pti(+band) (legacy
constant 0.0); zip_code (legacy 3-digit truncation); is_joint with snowflake_is_correct=False.

THE RE-CHECK AGAINST THE BACKFILL CHANGED THE ANSWER IN THREE PLACES - the notes' plan
(~/notes/areas/efp/projects/dev-1393-openroad-datastore/, single day 2026-07-01) would have been
wrong on all three:
1. credit_score REVERSED. The notes said register #2/#3 as an accepted data gap (silver NULL on
   all 35, datastore 17). The TU VantageScore fix landed 2026-08-01 (openroad_offers.py reads
   payload:transunionCreditAttributes:vantage4Score, PR #5974). Silver now has 34/35 and agrees
   exactly with the datastore on all 17 shared loans. Registered as SF-richer, not as a gap.
2. anl/irr/anl_band/irr_band RETIRED. The notes' #1 (0/35 EFP_IDs matching) is fixed in prod:
   34/34 exact agreement, residual 2.86% is one loan with no prediction. Not registered.
3. ef_score ADDED - not in the notes at all. Datastore has no EF_SCORE concept, silver has 34/35.

Also registered installment/installment_band, which the notes' own register-list omitted while
including pti - they are the same legacy no-op bug and the datastore reads 0.0 for 34/35 loans on
every date checked.

VERIFIED END TO END, not just imported: a no-write compare_daily_summary run for 2026-08-09 with
the file in place returns None for all 19 registered columns and keeps every other column's value.
ruff check, ruff format and mypy all clean.

CAVEAT WORTH KNOWING: registration is not display-only. compare_daily_summary skips verified
columns and writes NULL to gold.positions_comparison_daily, so these 19 series will stop plotting
on the OpenRoad board once this ships. northpond_verified.py's docstring claims the opposite
('does NOT affect the Grafana comparison board'); that claim is stale - the skip landed 2026-07-28
in PR #6040, and northpond's own registered columns read NULL in PROD gold today. Not fixed here
(other platform's file, not this ticket).
