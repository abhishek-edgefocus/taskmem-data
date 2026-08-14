---
id: wm-3sxcre
type: task
title: NorthPond data quality, mappings and reporting
status: active
size: xl
people: [Abhijeet]
tags: [northpond, data-quality, reporting]
links: [parent:wm-j523sq]
created: 2026-08-14T19:56:57Z
updated: 2026-08-14T19:57:10Z
source: claude-code
label: NorthPond DQ + reporting
---

Third and last of the Oliv/NorthPond threads, created 2026-08-15 when Abhishek asked for the work
to be clubbed into two or three threads. The other two are deal-driven and error-driven; this one
is everything else — the steady-state correctness and reporting work that has no external date and
no partner waiting on it.

It is deliberately a QUEUE, not a checklist. Nothing in here blocks anything else in here, and
saying otherwise would make the chain view lie. What it does have is two natural clusters:

MAPPING AND BACKFILL CORRECTNESS — silver columns that are wrong, null or derived from the wrong
source. The status_at_purchase nulls, the ACCOUNT_ID derived from the raw tape instead of the
fund, the FULLY_PAID_DATE mapping, the cfframe capture gap going back to Feb/Mar 2025, and the
markup/exposure/purchase_year semantics question. These are the ones that quietly corrupt
downstream reporting, and they are the half worth doing first.

REPORTING SURFACES — the EF-vs-Oliv prediction comparison dashboard, the Fund Monitoring
integration, the fund-returns panel that copies FPM's JV-keyed query where efhyf has no FUND_KEY,
and the 'only unverified' filter on the comparison board. Plus the Linear restructure to split
v1/v2 model reporting out of the deprecation milestone.

Sitting here too: enabling CMOP + BEP for NorthPond, which is the counterpart of the OpenRoad work
and was confirmed outstanding on both platforms in the 2026-07-29 exchange with Abhijeet.

## Next steps
- Pick from the mapping/backfill cluster first — those affect numbers other people read.
- The two backfills (status_at_purchase nulls, ACCOUNT_ID) are the cheapest and the most directly
  wrong.

## Links
- Project: [[wm-j523sq]]
- Sibling threads: [[wm-d7m3xz]] (EDGEX deal) and [[wm-d3qnqe]] (Oliv error surface)
