---
id: wm-k3wt84
type: task
title: NorthPond purchased loans take 2-8 days to appear in silver.positions (portfolio understated after each purchase)
status: inbox
tags: [northpond, data-quality]
links: [relates:wm-j9jxpc, relates:wm-rgwdyu]
created: 2026-07-16T13:06:33Z
updated: 2026-07-16T13:06:38Z
source: claude-code
---

Found while verifying the missing-file gaps for wm-j9jxpc (surfaced by Abhishek's "did we actually buy loans on those dates?" challenge). NOT caused by any missing file — this is independent.

Every early NorthPond purchase appears on the daily loan tape only DAYS after the purchase date. Lag from silver.transfers purchase date -> first AS_OF_DATE in silver.positions:

    OLV12562547  purchased 2024-07-02 -> first seen 2024-07-10  = 8 days
    OLV12562548  purchased 2024-07-23 -> first seen 2024-07-26  = 3 days
    OLV12562549  purchased 2024-08-01 -> first seen 2024-08-03  = 2 days
    OLV12562550  purchased 2024-08-05 -> first seen 2024-08-10  = 5 days

Confirmed platform-side, not a transform bug: the 2024-08-06 / 08-07 / 08-08 tapes all arrived and simply do not contain OLV12562550.

Later loans (2025-10 onwards) show a consistent 1-day lag, so this may be an early-portfolio-only artifact that has since settled — needs confirming.

Why it matters: during the lag window we own the loan but silver.positions does not show it, so portfolio / exposure is understated on those days. Relevant to the NorthPond Fund Monitoring migration (wm-rgwdyu, DEV-1395) if any panel reports point-in-time holdings or exposure.

## Next steps
1. Widen the lag query past 2024 to see whether the 1-day lag holds across the whole current portfolio or whether multi-day lags recur.
2. If early-portfolio-only, note it and close — no action needed.
3. If it recurs, decide whether positions should be backfilled from the purchase date (silver.transfers already holds the true purchase date) or whether it is accepted platform behaviour.

## Provenance
Query: silver.transfers (EVENT_TYPE='purchase') joined to MIN(AS_OF_DATE) from silver.positions, PLATFORM='northpond'. Verified read-only against PROD 2026-07-16.
