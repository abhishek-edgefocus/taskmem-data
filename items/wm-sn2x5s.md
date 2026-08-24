---
id: wm-sn2x5s
type: task
title: OpenRoad ITD cash flows diverge from the datastore from 2026-05-01 (silver massively under-counts)
status: open
priority: p1
tags: [openroad, data-quality, datastores]
links: [relates:wm-jr5bup, relates:wm-skvqac]
created: 2026-08-24T13:10:59Z
updated: 2026-08-24T13:11:05Z
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
