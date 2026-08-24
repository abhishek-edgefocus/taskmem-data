---
id: wm-sn2x5s
type: task
title: OpenRoad ITD cash flows diverge from the datastore from 2026-05-01 (silver massively under-counts)
status: open
priority: p1
tags: [openroad, data-quality, datastores]
links: [relates:wm-jr5bup, relates:wm-skvqac]
created: 2026-08-24T13:10:59Z
updated: 2026-08-24T20:13:17Z
source: claude-code
---

Found 2026-08-24 while re-verifying the OpenRoad by-design differences for DEV-1638 ([[wm-skvqac]])
against the freshly backfilled 142-date comparison. This was INVISIBLE before the backfill, because
the comparison had COMMON_COUNT=0 on those dates and so compared nothing ([[wm-vzrdrm]]).

WHAT IS WRONG. silver.positions ITD cash-flow columns for openroad fall far behind the legacy
datastore, starting 2026-05-01:
  - 2026-03-21: the two agree on 35/35 loans, all three payment legs. Clean.
  - 2026-07-15: they agree on 1 of 35. Silver reports a small fraction of the datastore's
    inception-to-date totals, or nothing at all:
      openroad_5011302  principal  DS 7218.63   SF  268.43
      openroad_4976517  principal  DS 9115.19   SF    0.00
      openroad_5011302  interest   DS 5898.81   SF  141.49
      openroad_5011302  transaction DS 13117.44 SF  409.92
  - Across the 142 dates 2026-03-21..2026-08-09: ITD_PAYMENT_PRINCIPAL/INTEREST/TRANSACTION_RECEIVED
    run to 97.14% mismatch on 57 dates (first nonzero 2026-05-01); the ITD_RECOVERY_* legs to
    11.43% on 44 dates (first nonzero 2026-06-27).

WHY IT MATTERS. These are the realized-cashflow columns. A 35-loan book where silver says a loan has
received 268.43 of principal and the datastore says 7218.63 cannot be signed off as datastore-ready,
so this blocks the OpenRoad datastore deprecation ([[wm-jr5bup]], DEV-1486) independently of
everything else in that thread. It is also the reason DEV-1638's verified-differences file does NOT
register these columns - suppressing them would hide this.

TWO HYPOTHESES, neither tested yet:
1. A backfill artifact: the 2026-08-22 rebuild recomputed silver.positions for historical as-of
   dates against a silver.transactions/transactions_itd history that is itself incomplete for
   mid-2026, so ITD stopped accumulating. Argues for re-checking silver.transactions coverage by
   as-of date before touching any transform.
2. A real join/derivation defect in the ITD wiring that only bites after a certain date.
Against (1) alone: 2026-03-21 is perfect and the divergence starts sharply on 2026-05-01, which is a
date, not a gradual falloff.

## Next steps
1. Count silver.transactions for openroad by month and compare against the datastore's transaction
   file for the same window - establish whether the transactions are missing or the rollup is wrong.
2. Check whether openroad_realized_cashflows_* and gold metrics read the same under-counted numbers.
3. Only then decide transform fix vs re-backfill.

## Provenance
Read-only, 2026-08-24. Legacy parquet from s3://efp-derived/datastores/openroad/positions/ joined to
PROD.SILVER.POSITIONS on EFP_ID for 2026-03-21 / 2026-07-15 / 2026-08-09, plus per-column stats over
DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY for the 142 backfilled dates.

## Log
- 2026-08-24T14:59Z [claude-code] ROOT-CAUSED 2026-08-24. Not a transform bug and not missing source data - it is stale incremental output that was never rebuilt.

THE SOURCE IS FINE. PROD.SILVER.TRANSACTIONS for openroad holds 1,260 rows, 34 loans, 2023-08-26..2026-08-21. Full history.

WHAT ACTUALLY HAPPENED, from the write timestamps on 2026-08-21:
  06:43-06:44  transactions + transactions_itd built for as-of dates 2026-07-01 onward, at a moment
               when silver.transactions still held ONLY July/August rows (pre-backfill state).
  13:00        silver.transactions backfilled with the full history.
  13:33        transactions_itd rebuilt - but only for as-of dates <= 2026-06-26.
The 06:44 rows were computed off a truncated transaction history and were never recomputed. So ITD
did not stall, it RESET: openroad_5011302 reads ITD_PAYMENT_PRINCIPAL 6,950.20 on 2026-06-26 (13:33
batch) and 268.43 on 2026-07-02 (06:44 batch), then climbs again from near zero - 539.76 by 08-09.

THE CODE ALREADY DOCUMENTS THIS FAILURE MODE. transactions_itd.py's module docstring: 'a correction
effective on date D is not propagated to already-built dates after D unless those dates are also
reprocessed (or a full --date all rebuild runs). That forward staleness is a fundamental limitation
of the incremental approach, not a bug.' The backfill is that case at full scale - the whole history
landed after the forward dates were built.

BLAST RADIUS, openroad: 46 as-of dates (2026-07-01..2026-08-15) served by the stale batch, plus 9
as-of dates between 2026-06-27 and 2026-08-21 with NO transactions_itd row at all. Downstream:
silver.positions ITD columns, then openroad_realized_cashflows_from_purchase /
_from_first_purchase / _from_origination and any gold metric reading realized cash.

THE FIX (no code change): rerun the ITD build for the affected window, then rebuild positions for
those dates so the columns propagate -
  python -m ...statement_rows.transactions_itd --platform openroad --date 2026-06-27:2026-08-24
Needs prod write, so it is a Dagster run, not something we can do from dpx.

WIDER SIGNAL, NOT YET PROVEN: ITD is monotonic by definition, so a decrease is impossible in correct
data. Counting decreases in PROD.SILVER.TRANSACTIONS_ITD since 2026-01-01: marlette 20,515 across
15,071 loans (worst drop 59,126.18), upgrade 11,067/4,895, prosper 6,521/3,005, sofi 4,059/2,574, lc
374, happymoney 372, anchored 96, openroad 15, innovate 15, upstart 2. Some of those will be
legitimate payment reversals or corrections rather than this bug - do NOT report them as corruption
without checking. But the same incremental-staleness mechanism applies to every platform, and a
monotonicity assertion would be a cheap standing check.
- 2026-08-24T16:47Z [claude-code] RERUN VERIFIED 2026-08-24. Abhishek launched statements_openroad (run 09ba8fe9-24a4-46ef-bbf0-c4744017e0d0), all 15 assets SUCCESS - openroad_transactions_itd 2,833s, openroad_positions 195s, plus the four realized-cashflow assets. Recompared 58 dates 2026-06-20..2026-08-16 against the legacy parquet.

THE ORIGINAL DEFECT IS FIXED. The 97% wall is gone from 48 of the 52 affected dates.
  - stale pre-backfill ITD rows in the window: 46 dates -> 0
  - impossible ITD decreases for openroad since 2026-06-01: 15 -> 0
  - openroad_5011302 at 2026-07-15: 268.43 -> 7,218.63, an exact match to the datastore
  - nothing else moved: PRINCIPAL, STATUS, ACCRUED_INTEREST and EXPOSURE all still 0.00% on every
    date, EXTRA_IN_DATASTORE 0, COMMON_COUNT 35 throughout, and every registered column unchanged
    (POOL_ID 100, ZIP_CODE 100, CREDIT_SCORE 48.57, REMAINING_TERM 45.71, AS_OF_MONTH 57.14).

BUT THE LEGS ARE NOT 100% CLEAN, and what is left is a SECOND, DIFFERENT BUG - not residue of this
one. 10 of 58 dates still show a payment-leg mismatch:
  2026-06-27..06-30  97.14% on all three payment legs, 8.57/11.43% on the recovery legs
  2026-07-03..07-06  2.86% (1 loan)
  2026-07-17..07-18  5.71% (2 loans)

THE 4 BIG ONES ARE A TRAILING-GAP HOLE IN transactions_itd. It is NOT a source gap:
silver.openroad_stmt_positions has all 35 loans on each of 2026-06-27..06-30, and my rerun range
(2026-06-27:2026-08-24) explicitly covered them. transactions_itd still emitted NO rows for those
four dates, so positions joins nothing and reads ITD = 0 for all 35 loans while the datastore shows
~484k. Mechanism, from the transaction calendar: openroad transactions land on 06-22, 06-24, 06-26,
then not again until 07-01. ITD rows exist through 06-26 and resume 07-01. The transform does not
carry the cumulative value forward across an as-of range that trails the most recent transaction.

THIS IS LIVE, NOT JUST HISTORICAL. Exactly 7 as-of dates in the last year have zero ITD on
silver.positions: 2026-06-27, 06-28, 06-29, 06-30 - and 2026-08-22, 08-23, 08-24. The last
transaction is dated 2026-08-21, so the three most recent days of OpenRoad positions carry zero
realized cash right now, and any new day will too until the next transaction lands. Re-running the
same job will not fix it; it needs a carry-forward fix in the ITD transform (or positions holding
the last known ITD across a no-activity gap).

The 6 small dates (1-2 loans, 2.86-5.71%) are the pre-existing settlement-timing noise that was
visible from 2026-05-01 onward and is unrelated to the batch staleness.
- 2026-08-24T19:04Z [claude-code] SCOPE DECISION + FIX 2026-08-25. Abhishek scoped this to OpenRoad only: no shared-file changes, no cross-platform backfill signed off. My recommendation had been to fix the bound in transactions_itd; he overrode it and the platform-scoped route turned out to be cleaner than either of us expected.

THE FIX IS ONE PARAMETER, NOT NEW LOGIC. positions_utils already supports itd_join_mode='asof',
already documents this exact failure mode in its docstring, and figure/positions.py already opts
into it (its tape outlives its transactions by 42 days). OpenRoad now passes the same flag from
generate_temp_table. asof takes the most recent ITD row on or before the position date: inside a
dense grid it selects the same row as exact so it is a no-op, outside it carries the last known
cumulative value forward, and it never fabricates a value where no prior ITD row exists. It is
bounded by the position calendar, so it cannot invent rows past the end of the book. Verified the
flag reaches BOTH attach sites - the join in generate_positions_sql and _resync_itd_columns for
autofilled rows - so it is not half-applied.

Branch abhishek/openroad-itd-asof, commit 573ee77d, one file, +14/-1. ruff, mypy and the 19
openroad positions tests green. No PR opened yet.

NEAR MISS WORTH RECORDING. The first attempt copied positions.py from a workspace based on
main@5c0005322 onto a branch cut from origin/master@99c70e725, which silently REVERTED the
FULLY_PAID_DATE work (DEV-1539, [[wm-ay9uu3]]) that had landed in between - 33 deletions in a
change that should have been purely additive. Caught it only by reading the diffstat before
pushing. Rule: when moving a change between workspaces, re-apply the patch onto the target base,
never copy the file, and read --stat before pushing - a deletion count above your own edit is the
tell.

STILL OPEN AND DELIBERATELY NOT ACTED ON: silver.transactions_itd remains incomplete, and the same
exposure covers ~1.15M loan-date rows across 8 of 13 platforms with 6 trailing gaps open right
now. Written up for Abhijeet at ~/itd-trailing-gap-note.md on the Mac. foursight's 73 dates look
like a wider problem than a trailing edge and need their own look.
- 2026-08-24T20:13Z [claude-code] TESTED IN DEV_ABHISHEK VIA LOCAL DAGSTER 2026-08-25, PR #6459 (draft, +14/-1).

Stood up an isolated stack rather than using his: containers dagster-*-abhishek-itd, compose project
openroaditd, ports 13060/15060, reusing the existing dagster-abhishek-*:latest images so no rebuild,
mounting ~/claude-ws/openroad-itd/efp (master + the fix). Deliberately NOT ~/repos/efp, which his
Dagster mounts: it carries another session's uncommitted Ramp work and its positions.py predates
FULLY_PAID_DATE, so a run there would have written that column NULL into DEV_ABHISHEK. Confirmed the
right baseline afterwards - FULLY_PAID_DATE is populated on 13 loans in the output.

RESULT. DEV reproduced the defect exactly (2026-06-27..06-30 at zero across all 35 loans,
transactions_itd missing those dates). After the fix, SUM(ITD_PAYMENT_PRINCIPAL_RECEIVED):
  06-24  483,342.13 -> 483,342.13   unchanged (in grid, proves the no-op claim)
  06-25  483,342.13 -> 483,342.13   unchanged
  06-26  483,776.60 -> 483,776.60   unchanged
  06-27       0.00  -> 483,776.60
  06-28       0.00  -> 483,776.60
  06-29       0.00  -> 483,776.60
  06-30       0.00  -> 483,776.60
Against the legacy datastore on those four dates: all five ITD legs 0.00%, COMMON_COUNT 35, versus
97.14% on the three payment legs before. Zero monotonicity regressions.

THE SHARP FINDING. asof repairs MISSING ITD dates, not WRONG values in rows that exist. The first
DEV run fixed 06-27..06-30 and correctly left 07-02 onward reading the corrupted 268.43, because
that is genuinely the most recent row - DEV still held the pre-rerun transactions_itd. Rebuilding
transactions_itd in DEV first, then positions, gave the clean result. The two defects are
independent and #6459 addresses only the trailing-gap one. Worth stating in review so nobody expects
it to fix the other.

TWO DEV-ENVIRONMENT GAPS FOUND, both unrelated to the fix but blocking any dev transform test:
1. DEV_ABHISHEK.SILVER had ONE stream (RAMP_AI_TRANSACTIONS_STREAM) against PROD's 50. The run died
   on 'DEV_ABHISHEK.SILVER.POSITIONS_STREAM does not exist'. Created the 8 the OpenRoad chain needs
   with the same DDL prod uses (CREATE STREAM ... ON TABLE ...); OPS.CHANGED_KEYS already existed.
   Anyone testing a transform in a cloned dev database will hit this first.
2. orchestration/agent_env.py is in neither the June-built image nor the compose volume list, so the
   code location fails to import definitions.py ('No module named orchestration.agent_env'). Mounted
   it in my override. His own stack on :13053 probably has the same broken code location - worth
   checking, since it would mean his local Dagster has been dead rather than idle.
