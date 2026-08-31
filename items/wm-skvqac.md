---
id: wm-skvqac
type: task
title: Write openroad_verified.py and register the by-design OpenRoad positions differences
status: waiting
priority: p2
size: s
waiting_on: eshan-edgefocus, abhijeet-edgefocus, sanjali-efp (PR #6454 review)
nudge: 2026-09-01
people: [Frank]
tags: [openroad, datastores, data-quality]
links: [follows:wm-hecgua, parent:wm-jr5bup]
created: 2026-08-14T14:55:14Z
updated: 2026-08-31T15:48:21Z
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
- 2026-08-24T15:00Z [claude-code] PR IS NOW UP — state moved past the 13:26Z entry. PR #6454 'DEV-1638: Register OpenRoad verified positions differences' was created 2026-08-24 14:48Z, so commit 78b28d923 is no longer sitting unpushed on dpx. Currently isDraft=true; CI partially reported ('Select tests' SUCCESS, 'Run Tests' still running, integration skipped) at time of check.

Since Abhishek named this his #1 for today, the thing to watch is that it does not repeat the #6416 pattern — a green PR parked in draft with no reviewer requested. Once 'Run Tests' goes green the next actions are: take it out of draft, and request a reviewer (see wm-f7egzv — Eshan offered on 08-21 and still has not been assigned anything).
- 2026-08-24T20:47Z [claude-code] FINAL 123-COLUMN ACCOUNTING 2026-08-25, run off DEV_ABHISHEK with the ITD fix applied (PR #6459), materialized through the local dpx Dagster, compared over 51 dates 2026-06-27..2026-08-16. COMMON_COUNT 35 on every date, zero extra loans either side, so every figure is a value difference on a fully matched book.

  EQUAL       90 columns identical on all 51 dates
  BETTER      26 - the 22 registered silver-richer/silver-correct columns, plus MGR_MARK_DQ_BUCKET
                   and the three ITD payment legs (all three now explained, see below)
  AMBIGUOUS    2 - INTEREST_AT_PURCHASE (1 loan, accrual-day convention, silver reads the real
                   purchase transfer event) and PRINCIPAL_BAND (1 zero-balance loan, banding of 0)
  WORSE        5 - IS_JOINT, plus ANL / IRR / ANL_BAND / IRR_BAND

THE FIVE WORSE COLUMNS COME FROM EXACTLY TWO CAUSES, both documented, neither registrable without
an explicit decision:
1. openroad_5462736 - no model_responses event in bronze.api_events for its offer, and no
   UNIQUE_OFFER_KEY on its purchase-tape row, so silver builds no prediction. One loan of 35 gives
   the 2.86% on anl/irr/anl_band/irr_band. It is also the missing 1 in the 34/35 coverage on
   credit_score, application_id, income and ef_score - one loan explains all of it. Fixing it needs
   the model_requests/model_responses statement files ([[wm-bpmxnb]], DEV-1396).
2. IS_JOINT - 2 loans, rule not reproducible from bronze ([[wm-cv963k]]).

THE ITD FIX LANDED, measured end to end: the payment legs fell from 97.14% on 64 dates to a max of
5.71% on 6 dates, and BOTH recovery legs are now identical on every date. The 6 remaining dates are
2026-07-03..07-06 and 07-17..07-18, and they are no longer unexplained - see [[wm-sn2x5s]].

RECOMMENDATION ON THE THREE ITD PAYMENT LEGS: leave them UNREGISTERED despite now being explained
and despite silver being the more correct side. Registering blanks all three series on the board,
and that is precisely the signal that surfaced the trailing-gap defect in the first place.
Explained-and-visible beats suppressed here.
- 2026-08-25T15:40Z [claude-code] ACCOUNTING UPDATED 2026-08-25 after the purchase-tape tiebreak (PR #6470) and the ITD asof fix (PR #6459), both verified in DEV_ABHISHEK through the local dpx Dagster. Same 51-date window, COMMON_COUNT 35 throughout.

  EQUAL      90 -> 92
  BETTER     26 (unchanged)
  AMBIGUOUS   2 (INTEREST_AT_PURCHASE, PRINCIPAL_BAND)
  WORSE       5 -> 3  (IS_JOINT, ANL, ANL_BAND)

IRR and IRR_BAND went to IDENTICAL - they leave the mismatch list. ANL/ANL_BAND remain at 2.86%
only because silver.predicted_cashflows is a VIEW onto PROD in DEV and PROD's purchase tape still
carries the unresolvable uuid; IRR could resolve in DEV because it reads silver.predictions
directly, and it did. That is the best available evidence ANL follows in prod, but it is not proof -
do not claim it until prod regenerates.

Several registered columns moved UP by exactly 2.86pp each (CREDIT_SCORE 48.57->51.43,
APPLICATION_ID/INCOME 45.71->48.57, PTI 60.00->62.86). That is one loan of 35: silver now covers
35/35 where the datastore covers fewer, so the mismatch grows because Snowflake got richer. Worth
remembering when reading the board - a rising percentage on a registered coverage column is the
good direction.

So the bar for [[wm-skvqac]] now rests on: IS_JOINT ([[wm-cv963k]], rule not reproducible) and
ANL/ANL_BAND pending the prod ship.
- 2026-08-31T15:48Z [claude-code] STATUS CORRECTED 2026-08-31 by the sync sweep — this item was still 'next' and its body still said the work was BLOCKED on the OpenRoad silver chain. Both are stale. The file is written, the PR is open, and it has been sitting unreviewed for five days.

GROUND TRUTH FROM GITHUB 2026-08-31: PR #6454 'DEV-1638: Register OpenRoad verified positions differences' is OPEN, NOT a draft, mergeStateStatus UNKNOWN, three reviewers requested since 2026-08-26 (eshan-edgefocus, abhijeet-edgefocus, sanjali-efp) and ZERO reviews submitted — no comments, no approvals, nothing. Linear DEV-1638 is 'In Review' with no comments. Its sibling #6459, requested at the same moment from the same three people, got Scott's review and approval within an hour and merged the next day; this one got nothing.

WHY IT IS WORTH CHASING RATHER THAN WAITING OUT. Abhishek already chased it once, in DM 2026-08-26 23:20 IST: 'Hya PR aaj / udya madhe baghshil ka? ... Scott ni he wali nahi baghitli, maybe idea nasel mhanun' (Scott hasn't looked at this one, maybe because he lacks the context). Abhijeet's reply exposed the real problem — he did not know why the file was wanted at all: 'openroad ingestion jhala hota na' (the OpenRoad ingestion was done, wasn't it?) and 'verified differences kon magtoy' (who is even asking for verified differences?). Abhishek answered 'sahebanni vicharla hota ki he file ka nahi aahe' (Frank asked why this file isn't there). Abhijeet then suggested Sanjali as the reviewer who knows autos, which is why she is on it.

So the reviewers are in place but at least one of them does not have the provenance. The nudge that works here is not 'please review' — it is the one line of context: Frank asked for this on the Datastore Retirement doc 2026-08-12, and PR #5807 is the evidence the validation was already done.

NEXT: nudge the three reviewers with that framing (Sanjali first, per Abhijeet). The remaining 'reply to Frank on the Linear doc pointing at PR #5807' step in Next steps is still open and should follow the merge.
