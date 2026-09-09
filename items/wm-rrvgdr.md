---
id: wm-rrvgdr
type: followup
title: Answer Nate: spot-check Oliv credit-pull errors to confirm they are the OAuth token issue
status: dropped
priority: p1
size: s
due: 2026-08-03
people: [Nate]
tags: [northpond, needs-reply, api-health]
links: [relates:wm-u52nd6, parent:wm-3y3ckv, parent:wm-d3qnqe, blocks:wm-u52nd6]
refs: [thread=https://edgefocuspartners.slack.com/archives/C04474NRLP6/p1785434540555299]
created: 2026-07-31T12:55:10Z
updated: 2026-09-09T13:16:47Z
source: claude-code
label: Nate spot-check token errors
---

#team-devops thread 2026-07-30 (parent ts 1785434540.555299), started by Nate:
"Is there a way for us to do another pass at 'errors' being returned from the Experian
Credit Report Pull API?" — on the Oliv end all that arrives is
`errorMessages: ["Internal Server Error", "Server Error: Experian Credit Pull Failed"]`.
He asked whether more extensive messages reach the Edge Focus model and are scrubbed before
flowing through to Oliv, and noted: **"as total volume is picking up, the absolute error
volume is also picking up."**

Abhishek pointed him at the 07-24 #api-offers-daily analysis. Nate's reply — still
UNANSWERED — was: **"is there a way to spot check a few requests to confirm if they are
indeed from the token issue?"**

So there are two things owed here:
1. The spot check itself — pull a handful of recent failing requests and confirm they are
   the Experian OAuth 401, not something else. This is the direct ask.
2. A view on error-message passthrough: Oliv sees only a generic string. Whether we can
   surface a more specific reason to the partner is a separate design question he raised
   first and nobody addressed.

WHY THIS MATTERS MORE THAN THE ORIGINAL TRIAGE SAID: the 07-24 conclusion was "~1-2
apps/day, within normal range, low impact" ([[wm-unzbpr]]). Nate is now reporting error
volume rising with total volume. That erodes the premise the low priority on [[wm-u52nd6]]
(DEV-1478) was set from — the fix and this spot check should be looked at together.

## Log
- 2026-08-20T19:20Z [claude-code] SPOT CHECK DONE 2026-08-20 (this is the ask Nate has been owed since 08-03). Measured directly off the gateway endpoint_transactions in s3://efp-raw/gateway/northpond/northpond_loan_fl/2026-08-19/v2/, window 2026-08-19 11:34-13:32 UTC (the window Abhishek pulled up on the sterling Grafana production-traffic dashboard).

NUMBERS: 1,273 get-offers requests. 7 hard errors (HTTP 500), all one signature: errorMessages=['Internal Server Error','Server Error: Experian Credit Pull Failed']. 1,187 clean. 79 returned HTTP 200 with creditGrade=NULL and no error at all (the silent degraded mode -- 63 missing clarityReport features, 4 missing creditReport features).

EVIDENCE THE 7 ARE THE AUTH BUG, NOT A TIMEOUT -- from serialized_tracepoints, duration of process_api_call:response_experian_api:
  hard errors (n=7):        min 0.058s  p50 0.203s  max 0.388s
  success w/ grade (n=1187): min 0.620s p50 1.001s  max 2.500s
The failing calls come back ~5x FASTER than a real credit pull. That is an immediate rejection at the auth layer (401), not a read timeout -- the handler's read timeouts are 3.0s/5.0s and would show as multi-second durations. So DEV-1478's diagnosis is confirmed by measurement, and this also confirms ERROR-1178 (read timeout, uat host) is a genuinely DIFFERENT failure mode.

RE-PRICES THE TICKET: 7 errors in a 1h58m window = 0.55% of requests. The July triage premise was '~1-2 apps/day, within normal range' and the low priority on [[wm-u52nd6]] was set from that. At 08-19 volume (13,432 requests that day) that premise is dead -- Nate was right that absolute error volume is tracking total volume. Full-day error count still being computed.

STILL OWED TO NATE: the reply itself, plus his second question on error-message passthrough (Oliv only ever sees the generic string -- confirmed again here, the response body carries nothing but 'Server Error: Experian Credit Pull Failed').
- 2026-08-20T19:53Z [claude-code] FULL-DAY NUMBERS for 2026-08-19 (all 13,432 northpond_loan_fl get-offers transactions scanned, supersedes the window-only figures above):
- 27 hard errors (HTTP 500) = 0.20% of requests. NOT ~1-2/day. The 11:34-13:32 window Abhishek was looking at ran ~2.7x hotter than the daily average, so do not extrapolate from it -- quote 27/day.
- 12,569 clean. 836 (6.22%) returned HTTP 200 with creditGrade=NULL.
- DIRECT PROOF, not just timing inference: 26 of the 27 carried the generic 'Server Error: Experian Credit Pull Failed', but ONE leaked the underlying Experian response verbatim -- errorCode '401', message 'Access token is invalid' (app_uuid=c0d28cb3-52cb-4e4d-be43-048f4b84d381, request_uuid=9cf9adce-1152-43ac-8bba-fbd0b30bc562). That is the DEV-1478 root cause caught in prod on 2026-08-19, and it is character-for-character ERROR-1280's title signature -- so ERROR-1280 is confirmed same-root-cause, merge it.
- Experian call duration: errors n=26 p50 0.124s max 0.559s; successes n=12,569 p50 0.887s. ZERO errors slower than 2.5s all day, i.e. no timeout-shaped failures at all. Every hard failure on 2026-08-19 was the auth path.
- Errors spread across 14 of 24 hours, no single burst -- steady low-rate leak, consistent with per-worker token invalidation rather than an incident.
- The 836 nulls break down: 440 missing BOTH clarityReport and creditReport features, 184 clarityReport only, 81 creditReport only, and 131 with NO missing-feature list at all (unexplained sub-case, worth its own look under DEV-1490 / [[wm-ufw7kj]]).
Raw evidence retained on dpx at /tmp/ab_np/day (13,432 files) and scripts /tmp/ab_day.py, /tmp/ab_scan3.py -- /tmp is not durable, re-derive from s3://efp-raw/gateway/northpond/northpond_loan_fl/<date>/v2/endpoint_transactions/ if needed later.
- 2026-09-09T13:13Z [claude-code] Slack sweep 2026-09-09: confirmed STILL unanswered and it is the last message in the thread. Nate's exact ask (#team-devops 2026-07-30 23:32 IST, thread 1785434540.555299, msg 1785442467.851169): 'is there a way to spot check a few requests to confirm if they are indeed from the token issue?' — asked directly after Abhishek pointed him at the OAuth-token explanation. 40 days open to an external partner. Note the OAuth 401 handling fix itself is done (wm-u52nd6), which should make the spot-check answerable now.
- 2026-09-09T13:16Z [claude-code] Dropped 2026-09-09 on Abhishek's instruction: discarding reply-debts older than two weeks. Nate asked this on 2026-07-30 (40 days). Not answered, and now deliberately not answering — if it resurfaces it comes back as a fresh ask with fresh context, which is more useful than a 6-week-late spot check. Note the underlying OAuth 401 fix did ship (wm-u52nd6), so the substance is handled even though the reply never went.
