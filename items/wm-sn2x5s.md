---
id: wm-sn2x5s
type: task
title: OpenRoad ITD cash flows diverge from the datastore from 2026-05-01 (silver massively under-counts)
status: open
priority: p1
tags: [openroad, data-quality, datastores]
links: [relates:wm-jr5bup, relates:wm-skvqac]
created: 2026-08-24T13:10:59Z
updated: 2026-08-24T14:59:58Z
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
