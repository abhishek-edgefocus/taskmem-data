---
id: wm-wvdxs4
type: task
title: NorthPond API outage 2026-07-16→21: blank currentAddress.line1 rejected 3,116 apps
status: next
priority: p1
size: s
people: [Kabeer]
tags: [northpond]
links: [parent:wm-d3qnqe]
created: 2026-07-22T13:47:21Z
updated: 2026-08-14T19:57:13Z
source: claude-code
---

Kabeer flagged northpond on the "Production API health — 2026-07-20" report
(#api-offers-daily, https://edgefocuspartners.slack.com/archives/C01J3CY12KW/p1784643021908079).

## What happened
From **2026-07-16 22:00 UTC to 2026-07-21 18:00 UTC**, 3,116 of 3,332
northpond_loan_fl (v2/EXP) requests — 93.5% — were rejected with:

    Invalid Request from Platform
    ['consumerPii.primaryApplicant.currentAddress.line1 has length 0; must have length at least 1']

Peak days: 07-17 829/864, 07-18 648/683, 07-19 533/551, 07-20 673/708.
Only ~5% of applications got a credit grade on those days (vs ~93% normal).

## Root cause: counterparty side
`has_min_length` in lib/efp/json_endpoints/validation.py returns early on
None, so the error means line1 arrived as an **empty string**, not missing —
the caller started sending `"line1": ""`. No EFP-side change explains it:
`git log origin/master --since=2026-07-01 -- lib/efp/json_endpoints/` has zero
northpond/validation commits (schema at
lib/efp/json_endpoints/platforms/api/northpond/v2/incoming_pii.py last touched
2025-12-09, d5c95ebec). Stopped by itself at 07-21 17:58 UTC with no deploy on
our side. Not reproducible from bronze.api_events — v2 PII scrubbing strips
line1 before persistence.

## Recovered? No
None of the 3,116 application_uuids were ever re-sent successfully — those
applications were never scored. 07-22 is clean (195/213 graded).

## Also found
Separate earlier blip 07-12/07-13: 279 requests failed with Experian OAuth 401
"Your account is in invalid state" (EFP-side credential/account issue, since
resolved).

## Not a bug: 0% approval
northpond_loan_fl `decision` is FALSE on every request in the table's history
(approved_apps_count = 0 since 2024) — v2 returns a credit grade, not a bid.
The 0% approval / $0 bid in the daily API summary is by design and should go in
the operator-notes doc so the health agent stops flagging it:
https://docs.google.com/document/d/1sJRAzAt6-GIfLx9sP0hcGWchEokd3G7eKHuy64wBYBk

## Next steps
1. Reply to Kabeer in the thread (draft prepared).
2. Add two entries to the operator-notes doc: northpond 0%-approval-expected,
   and (Abhijeet) foursight latency.
3. Ask whether NorthPond/Oliv should be told + whether the 3,116 apps get
   re-sent for scoring.
4. Consider alerting: 93% platform-validation-reject for 5 days went unnoticed
   by #errors-api.

## Log
- 2026-07-23T10:08Z [claude-code] Correction to next-step 4: #errors-api DOES fire per-request 'Invalid Request from Platform' alerts (seen live for northpond/openroad/foursight/prosper on 2026-07-23), so the line1 rejects almost certainly alerted thousands of times and were lost in per-request noise. The gap is aggregation/rate-based alerting, not missing alerts.
- 2026-07-27T10:07Z [claude-code] 2026-07-24 health report re-flagged northpond (Experian credit-pull). Triaged in wm-unzbpr: false positive (lifetime Sentry counter, 2 events on 07-24 vs 1.2K apps). Confirms next-step 2 is still open — operator-notes doc still has NO northpond entry as of 07-27.
- 2026-07-28T17:39Z [claude-code] VERIFIED STILL OPEN 2026-07-28 — I read the actual thread rather than trusting the item. Kabeer's ask ('@Abhishek can u check northpond?') sits in the 2026-07-20 #api-offers-daily thread with NO reply from Abhishek; the whole visible thread is Kabeer and Abhijeet on foursight latency and the revolut note. Eight days unanswered. Note the 2026-07-24 thread reply covered the Experian 401s only ([[wm-unzbpr]]), NOT this line1 outage, so it does not discharge this.
Next-step 2 (northpond 0%-approval-expected in the operator-notes doc) also still open — Kabeer fixed the agent account's doc access on 07-27, so the blocker to writing it is gone. That entry is now tracked ONLY here, since [[wm-unzbpr]] closed today.
