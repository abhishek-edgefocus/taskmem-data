---
id: wm-unzbpr
type: task
title: Triage northpond Experian credit-pull flag on 2026-07-24 API health report (Frank)
status: active
priority: p2
size: s
people: [Frank, Kabeer, Abhijeet]
tags: [northpond, api-health]
links: [parent:wm-j523sq, related:wm-wvdxs4]
created: 2026-07-27T10:07:14Z
updated: 2026-07-27T14:43:13Z
source: claude-code
---

Frank flagged this to Abhishek in the "Production API health — 2026-07-24"
thread (#api-offers-daily,
https://edgefocuspartners.slack.com/archives/C01J3CY12KW/p1784988589560619):
"the Oliv credit pull failures seem odd!"

Report claim: northpond_loan_fl has *active* Experian credit-pull failures —
"98 errors in Sentry, growing, 2 ALB 5xx, plus widespread degraded responses
with null creditGrade".

## Finding: the Sentry part is a false positive (same class as revolut/foursight)

Sentry EFP-ERRORS-AW "[northpond_loan_fl] Server Error: Experian Credit Pull
Failed: ... Missing: credit profile, Clarity report"
(https://edgefocus.sentry.io/issues/EFP-ERRORS-AW, linear ERROR-400):
- **First seen 2025-12-19**, not new. Lifetime occurrences 98 on 07-24 →
  111 on 07-27. The "98, growing" number is the issue's LIFETIME counter,
  not a 07-24 count.
- Actual events **on 2026-07-24: 2** (02:19 and 17:13 UTC), against 1.2K
  northpond applications that day (EFP DEV summary) = **0.17%**.
- Last 30d: 33 events ~= 1.1/day, flat. Per-day: 06-27..07-16 mostly 1-2/day;
  **07-17 -> 07-21 = ZERO** (the line1 outage window, wm-wvdxs4 — requests were
  rejected before ever reaching Experian, which corroborates that window);
  07-22 3, 07-23 2, 07-24 2, 07-25 5, 07-26 1.
- The "2 ALB 5xx" are the SAME 2 events (gateway 500s when the pull fails),
  not independent evidence.
- Error semantics: "Missing: credit profile, Clarity report" = Experian
  returned no credit profile / no Clarity report for that consumer — a
  per-applicant no-hit/thin-file condition, not an integration failure.

Real Experian integration failures look different and did NOT occur on 07-24:
EFP-ERRORS-1J5/1B9/1BB (OAuth 401 "account is in invalid state"), 264 events
confined to 2026-07-12 22:51 -> 2026-07-13 13:12 UTC, now resolved (Kabeer
raised with Nate at the time; also recorded in wm-wvdxs4).

## Open: the "widespread null creditGrade" claim — UNVERIFIED
Cannot be checked from Sentry. Needs bronze.api_events / Snowflake for
2026-07-24: share of northpond_loan_fl responses with null creditGrade vs the
~93%-graded baseline (wm-wvdxs4). BLOCKED 2026-07-27: AWS VPN down on
Abhishek's Mac, so dpx and grafana.edgefocuspartners.com are both unreachable
(curl to grafana returns 000). Run when VPN is back before replying with a
definitive answer.

## Also found: operator-notes doc has no northpond entry
"Agent Notes — api_monitoring_review"
(https://docs.google.com/document/d/1sJRAzAt6-GIfLx9sP0hcGWchEokd3G7eKHuy64wBYBk,
modified 2026-07-27) contains only 3 lines: full-coverage reporting, revolut
no-prod-apps expected, foursight latency known. Kabeer fixed the agent account's
access to it on 07-27. The **northpond entries are still missing** — both the
0%-approval-is-expected note recommended on 07-22 (wm-wvdxs4 next-step 2) and a
new one for this: "Missing: credit profile, Clarity report" is a per-applicant
Experian no-hit at ~1-2/day baseline; flag only if the daily rate spikes.

## Report bug worth raising with Kabeer
The health skill read a Sentry issue's lifetime occurrence count as in-window
volume. Same failure mode could inflate any long-lived low-rate issue. Fix:
count events within the report window (issue.id + date filter), not issue.count.

## Next steps
1. When VPN is back: quantify null-creditGrade share for northpond on 07-24.
2. Reply to Frank in the thread (draft prepared — Abhishek posts it himself).
3. Add the two northpond entries to the operator-notes doc.
4. Tell Kabeer about the lifetime-counter bug in the health skill.

## Log
- 2026-07-27T14:43Z [claude-code] CORRECTION (2026-07-27, after external review + breadcrumb check): my 'per-applicant Experian no-hit/thin-file' root cause was WRONG. get_issue_breadcrumbs on EFP-ERRORS-AW latest event (07-27 10:03:43Z, app 1bf4fda5-7578-4e29-b946-cc982ae5d301) shows: 'Posting Experian credit pull request' -> httplib POST us-api.experian.com http.response.status_code=401 -> 'Post request response status: 401' -> "Experian response received: ['errors']" -> 'No creditProfile found in Experian response'. So it is an Experian AUTH REJECTION on the credit-report POST; 'Missing: credit profile' is the downstream symptom. No token-refresh breadcrumb precedes the 401 => cached bearer token reused and rejected. A genuine no-hit would be HTTP 200 with an empty creditProfile (reviewer cites lib/efp/experian_data/handler.py get_raw_credit_info: is_success = status_code == 200 -- not verified by me, no repo access from this Mac). Do NOT repeat the 'normal / no credit file' framing; the draft Slack reply built on it was withdrawn before posting.
