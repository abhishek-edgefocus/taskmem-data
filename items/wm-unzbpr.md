---
id: wm-unzbpr
type: task
title: Triage northpond Experian credit-pull flag on 2026-07-24 API health report (Frank)
status: done
priority: p2
size: s
people: [Frank, Kabeer, Abhijeet]
tags: [northpond, api-health]
links: [parent:wm-j523sq, related:wm-wvdxs4]
created: 2026-07-27T10:07:14Z
updated: 2026-07-28T17:38:36Z
source: claude-code
---

Frank flagged this to Abhishek in the "Production API health — 2026-07-24"
thread (#api-offers-daily,
https://edgefocuspartners.slack.com/archives/C01J3CY12KW/p1784988589560619):
"the Oliv credit pull failures seem odd!"

Report claim: northpond_loan_fl has *active* Experian credit-pull failures —
"98 errors in Sentry, growing, 2 ALB 5xx, plus widespread degraded responses
with null creditGrade".

## Root cause: intermittent Experian HTTP 401 on the credit-report POST

**Corrected 2026-07-27** (first pass wrongly called this a per-applicant
thin-file no-hit — see Log). Verified via Sentry `get_issue_breadcrumbs` on
EFP-ERRORS-AW's latest event (07-27 10:03:43Z):

    Posting Experian credit pull request for app_uuid: 1bf4fda5-...
    [httplib] POST https://us-api.experian.c... -> http.response.status_code: 401
    Post request response status: 401
    [1785146623431400884] Experian response received: ['errors']
    No creditProfile found in Experian response

So: Experian rejects the call with 401; "Missing: credit profile, Clarity
report" is the downstream symptom, not a consumer data condition. No
token-refresh breadcrumb precedes the 401 -> a cached bearer token was reused
and rejected. Reviewer cites lib/efp/experian_data/handler.py
get_raw_credit_info (`is_success = response.status_code == 200`), so a 401 is a
hard failure; a genuine no-hit would be HTTP 200 with empty creditProfile.
NOT verified by me — no repo access from Abhishek's Mac.

Hypothesis worth testing (mine, unproven): at ~0.17% of calls this is too rare
for a broken credential — it looks like a token-expiry race (request issued in
the instant the cached token expires, no refresh-and-retry on 401). If so the
fix is a forced refresh + single retry on 401.

Distinct from EFP-ERRORS-1J5/1B9/1BB, which were 401s on the *token* endpoint
("account is in invalid state"), 264 events confined to 07-12 22:51 -> 07-13
13:12 UTC, resolved.

## Two failure modes the report conflated
a. **Hard fail** -> HTTP 500 -> Sentry EFP-ERRORS-AW. ~2-5/day; 07-24 = 2,
   which are also the "2 ALB 5xx" (same 2 requests, not extra evidence).
b. **Incomplete pull** -> HTTP 200 with creditGrade=null, no exception, NEVER
   reaches Sentry. Reason bucket "Missing: Clarity report" ~13-36/day.
   Sentry-only monitoring cannot see (b) at all.

## The report's numbers were still wrong
- "98 errors, growing" = EFP-ERRORS-AW's LIFETIME total (firstSeen 2025-12-19;
  98 on 07-24 -> 112 on 07-27), not same-day volume. On 07-24 there were 2.
- "widespread degraded responses with null creditGrade": ~60 null-grade offers
  on 07-24 = ~5% of 1.2K apps. Baseline is ~93% graded (~7% null, wm-wvdxs4),
  so 07-24 was AT OR BELOW baseline. Not widespread.
- The real null-grade spike was 07-17 -> 07-21 (up to ~97% of offers null) =
  the already-root-caused `currentAddress.line1` outage (wm-wvdxs4), which
  ended 07-21 17:58 UTC. Not evidence about 07-24.
- Corroboration: EFP-ERRORS-AW had ZERO events 07-17 -> 07-21 — requests were
  rejected at validation before ever reaching Experian.

## Snowflake sources for (b) — run when VPN is up
gold.credit_pulls_daily (platform='northpond', event_type='experian_request';
total_failures + failure_reason_counts) and silver.northpond_exp_offers
(COUNT_IF(credit_grade IS NULL)). Reviewer already pulled these; re-run to
confirm independently.

## UNVERIFIED: possible PII in Sentry events
Reviewer reports EFP-ERRORS-AW events carry live applicant PII (SSN, DOB, name,
address) in the captured request body on the get-offers path. I could not
confirm or refute it — the Sentry MCP event view exposes no request body, and
the breadcrumbs show `[Filtered]` on several fields, so scrubbing is at least
partly active. Check the Request section of an event in the Sentry UI directly.
If confirmed it is a data-handling issue meriting its own ticket, separate from
this one.

## Also: operator-notes doc has no northpond entry
"Agent Notes — api_monitoring_review"
(https://docs.google.com/document/d/1sJRAzAt6-GIfLx9sP0hcGWchEokd3G7eKHuy64wBYBk)
has only 3 lines (full-coverage, revolut, foursight). Kabeer fixed the agent
account's access on 07-27. Still missing: northpond 0%-approval-is-expected
(wm-wvdxs4 next-step 2). Do NOT add a note calling these credit-pull errors
benign — they are a real, if small, auth bug.

## Report bug to raise with Kabeer
The health skill presented a Sentry issue's lifetime occurrence count as
same-day volume. Fix: count events filtered by issue.id + report date. Second
gap: credit-pull health cannot be judged from Sentry/ALB-5xx alone, because
mode (b) returns HTTP 200 — cross-check Snowflake.

## Next steps
1. File a ticket for the Experian 401 (refresh-and-retry on 401); EFP-ERRORS-AW
   is still unresolved, last event 07-27 10:03Z.
2. Confirm or kill the PII claim in the Sentry UI.
3. Reply to Frank (corrected draft prepared — Abhishek posts it himself).
4. Tell Kabeer about both monitoring bugs.
5. Add the northpond entry to the operator-notes doc.

## Log
- 2026-07-27T14:43Z [claude-code] CORRECTION (2026-07-27, after external review + breadcrumb check): my 'per-applicant Experian no-hit/thin-file' root cause was WRONG. get_issue_breadcrumbs on EFP-ERRORS-AW latest event (07-27 10:03:43Z, app 1bf4fda5-7578-4e29-b946-cc982ae5d301) shows: 'Posting Experian credit pull request' -> httplib POST us-api.experian.com http.response.status_code=401 -> 'Post request response status: 401' -> "Experian response received: ['errors']" -> 'No creditProfile found in Experian response'. So it is an Experian AUTH REJECTION on the credit-report POST; 'Missing: credit profile' is the downstream symptom. No token-refresh breadcrumb precedes the 401 => cached bearer token reused and rejected. A genuine no-hit would be HTTP 200 with an empty creditProfile (reviewer cites lib/efp/experian_data/handler.py get_raw_credit_info: is_success = status_code == 200 -- not verified by me, no repo access from this Mac). Do NOT repeat the 'normal / no credit file' framing; the draft Slack reply built on it was withdrawn before posting.
- 2026-07-27T14:52Z [claude-code] 401 investigation (Sentry-only, 2026-07-27). SHAPE: 100 events over 80 days (05-07 -> 07-27), ~1.25/day, rate FLAT-TO-DECLINING (May 41, Jun 31, Jul 28) - contradicts report's 'growing'. NOT isolated singles: 15 multi-event clusters, min gap 4 SECONDS, largest 10 events/87min (06-26 15:22-16:49Z) and 8 events/96min (05-08 00:52-02:28Z); cluster spans repeatedly cap out ~60-96 min. NEGATIVE CONTROL: the OAuth *token-endpoint* issues (1BA/1J5/1B9/1BB) fired ONLY 07-13 12:36-13:12Z in 90 days, so token ACQUISITION is healthy - tokens are being rejected at the credit-report POST. LEADING HYPOTHESIS (unproven): per-worker token cache (gunicorn -w2 = 2 independent caches) + Experian single-active-token semantics -> when worker B refreshes, worker A's token is invalidated and A 401s every request it serves until its own TTL expires; bounded by TTL, matching the ~60-90 min cluster ceiling. Alternative (plain expiry race, no refresh-on-401) explains singles but not 4-second repeats or 87-min bursts. Seer run 15505468 confirmed the 401 mechanism but had no repo insight; it did flag that the code continues into feature extraction after a non-200 instead of failing fast, which is why the error surfaces as 'Missing: credit profile' and misattributes the cause. FIX (holds either way): force token refresh + single retry on 401 from the report POST; fail fast on non-200 with an accurate auth error; consider a shared token cache across workers.
