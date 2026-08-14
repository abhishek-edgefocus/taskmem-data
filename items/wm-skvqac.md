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
updated: 2026-08-14T14:56:56Z
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
