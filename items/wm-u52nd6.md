---
id: wm-u52nd6
type: task
title: Fix Experian OAuth 401 handling in the northpond gateway (DEV-1478)
status: next
priority: p2
size: m
tags: [northpond, oncall, api-health]
links: [parent:wm-3y3ckv, relates:wm-9kvv8c, parent:wm-d3qnqe]
refs: [DEV-1478=https://linear.app/edge-focus/issue/DEV-1478/northpond-experian-credit-pulls-intermittently-fail-with-401-oauth]
created: 2026-07-29T13:43:02Z
updated: 2026-08-21T17:54:01Z
source: claude-code
label: Experian 401 OAuth fix DEV-1478
---

Filed by Abhishek on 2026-07-27 off the Frank triage ([[wm-unzbpr]], done) — but never had
a taskmem item, so the fix itself was untracked. Linear DEV-1478 is Backlog, assigned to
Abhishek, unstarted as of 2026-07-29.

THE BUG (as stated on the ticket and in Abhishek's #api-offers-daily reply 2026-07-24):
northpond_loan_fl (v2 / Experian) credit pulls intermittently return HTTP 500 to the
partner because Experian's credit-report POST responds with 401 Unauthorized. The applicant
is fine — the request is rejected at the auth layer. Cause: the two gateway workers share
one login and neither refreshes the token nor retries on a 401.

Impact is low and steady — ~1-2 applications/day, within normal range. Explicitly NOT a
spike: the "98 errors" figure Frank's report surfaced was that Sentry issue's cumulative
total since Dec 2025, not a 2026-07-24 burst.

Fix shape: refresh-on-401 + retry, rather than letting the stale shared token fail the pull.

Sentry: https://edgefocus.sentry.io/issues/7125718855/?project=4510478928510976&statsPeriod=90d&utc=true

Related, deliberately separate: [[wm-9kvv8c]] (does EFP-ERRORS-AW carry live applicant
PII?) is a Sentry-hygiene question, not this auth bug.

## Log
- 2026-07-31T12:55Z [claude-code] PRIORITY p3 -> p2 (2026-07-31). Nate in #team-devops 2026-07-30: 'as total volume is picking up, the absolute error volume is also picking up', and he asked for a spot check confirming the failures really are the token issue (unanswered — tracked as its own followup, see relates). The 'low impact, ~1-2 apps/day, within normal range' framing this item inherited from the 07-24 triage was measured before Oliv volume ramped, so it should not keep holding the priority down. The fix shape is unchanged: refresh-on-401 + retry on the shared gateway token.
Also note the two are now coupled — the spot check is the evidence that would confirm or kill this ticket's diagnosis, so doing it first is cheap and de-risks the fix.
- 2026-08-20T12:11Z [claude-code] Sanjali chased this in DM 2026-08-20 15:40 IST (D0BN47AEZ9N), linking ERROR-1178 and ERROR-400: 'any updates on the Experian pull errors?'. Abhishek replied same day committing to implement the fix NEXT WEEK (w/c 2026-08-24) — first hard-ish commitment on DEV-1478, previously open-ended. Also: Abhishek wants the scattered northpond Experian tickets clubbed as duplicates of ONE investigation ticket. DEV-1478 is the natural master (already relatedTo ERROR-400, carries the full diagnosis + fix shape). Candidate duplicates identified 2026-08-20: ERROR-400, ERROR-1280 (Cashflow API 401 'Access token is invalid'), ERROR-1178 (Cashflow API read timeout — transport not auth, weakest fit). CAVEAT surfaced while triaging: ERROR-1178 and ERROR-1280 are Sentry-linked and auto-flip Backlog<->Done on every regression (1178 has flipped ~11 times since May). Marking them Duplicate in Linear will NOT stop the churn — the Sentry issue has to be merged/resolved-in-next-release too, or they reopen. Nothing mutated yet; awaiting Abhishek's go-ahead.
- 2026-08-20T20:48Z [claude-code] 2026-08-20 12:19-12:20 UTC: the Experian credit-pull error cluster landed in Linear — ERROR-1178, ERROR-1280 and ERROR-400 are all now status=Duplicate, consolidated under DEV-1478 (Backlog, High). Sanjali's 15:40 IST ping pointed at ERROR-1178 and ERROR-400, both of which are now folded in. DEV-1478 remains the single open master.
- 2026-08-20T20:58Z [claude-code] FIX WRITTEN 2026-08-20, committed locally, NOT pushed (awaiting Abhishek's go-ahead).

WORKSPACE: dpx ~/claude-ws/dev-1478/efp, branch abhishek/dev-1478-northpond-experian-credit-pulls-intermittently-fail-with-401, commit e9640c85f off master 8c4303497.

ROOT CAUSE CONFIRMED IN CODE (lib/efp/experian_data/handler.py):
- get_raw_credit_info fetched a token only when __bearer_token was None or the LOCAL _token_expires_at clock had elapsed.
- The POST result set is_success = (status_code == 200). A 401 therefore returned (body, False) and left the cached token in place -- no invalidation, no retry.
- So a token retired server-side gets replayed by that worker until its local expiry elapses; every request routed to that worker 401s in ~0.1s until then. Matches the measured fast-failure signature and the steady all-day spread exactly.

BLAST RADIUS -- important for the 'no shared code changes' rule: handler.py lives under lib/efp/ but NorthPond is its ONLY consumer. CreditPulledChannel takes experian_config=None for every other platform (happymoney, revolut, credible, openroad, foursight, anchored, sofi, tare all run TU only); grep for experian_config under json_endpoints/platforms/ returns northpond_loan_fl_channel.py exclusively. So the file is shared by location, not by use. Worth stating in the PR so a reviewer does not read it as a cross-platform change.

ALSO LEARNED: northpond builds TWO ExperianCreditPull instances (scoring + cashflow), but _load_cashflow_credentials shows cashflow uses a SEPARATE Experian account, so those two do not contend for one token. The contention is strictly between gateway processes on the scoring credential.

THE CHANGE: rejection (401/403) -> discard token, re-authenticate, retry once; a second rejection fails as before. Refresh 60s ahead of stated expiry so a token cannot lapse in flight. Request still persisted exactly once so bronze/silver request-response pairing is unchanged. Dropped the dead refresh_time attribute and folded 3 copies of the token-reset block into one helper.

VALIDATION: ruff format + ruff check clean, mypy (legacy mypy.ini) clean, 38 tests pass (32 existing northpond_v2_api_test + 6 new). New file lib/efp/experian_data/handler_test.py -- the 4 behavioural tests were confirmed to FAIL against unpatched master and pass with the fix; the other 2 are invariants that hold on both.

NOT DONE / NEXT: nothing exercised against real Experian UAT -- the fix is unit-tested only. The retry has no jitter and no in-process lock, so if a burst of threads in one worker all 401 together they will each re-authenticate; acceptable at this volume but worth a note in review. Deploy/verify path still to be agreed.
- 2026-08-20T21:25Z [claude-code] PR OPENED (DRAFT) 2026-08-20: https://github.com/edgefocus/efp/pull/6416 -- 'DEV-1478: Recover from Experian token rejections by refreshing and retrying the credit pull'. Branch abhishek/dev-1478-northpond-experian-credit-pulls-intermittently-fail-with-401 pushed to origin, base master, +294/-30 across 2 files, isDraft=true. Body written to ~/pr-style.md conventions (what changed -> 'DAG - unchanged.' -> validation with exact counts -> out of scope -> Fixes sentry / Closes DEV-1478).

STAYS IN DRAFT UNTIL the evidence gap closes, per [[pr-draft-until-ready]]: the PR states plainly that nothing has been exercised against Experian UAT and that the fix is unit-tested only. The proof that actually closes this is a post-deploy re-run of the full-day gateway scan showing the 27/day 500s drop to ~0. Scan is reproducible from s3://efp-raw/gateway/northpond/northpond_loan_fl/<date>/v2/endpoint_transactions/ -- same method as the 2026-08-19 baseline logged on [[wm-rrvgdr]].

NO SCREENSHOTS attached -- there is no Snowflake table to query here so the style guide's usual proof genre does not apply; evidence is inline tables instead. If Abhishek wants an image, the Sentry EFP-ERRORS-AW 90-day graph is the one that shows 'long-standing and ongoing' at a glance.
- 2026-08-21T17:26Z [claude-code] 2026-08-21: DOPS-695 / PR #6425 (Samuel) proposes treating 'Missing: credit profile, Clarity report' as a no-hit decline. It is not a no-hit - it is THIS ticket. Verified on northpond_loan_fl/production/gateway over 24h: 11,283 Experian POSTs, 11,263x200, 16x400, 4x401; the 20 non-200s are exactly the 20 responses with no creditProfile (16 body ['errors'], 4 with headerRecordError/endTotalsError). DOPS-695's own sample times map 1:1 - 13:18:13Z 401, 14:08:03Z 400, 14:18:36Z 401, 14:51:00Z 401. Mechanism: handler.py:159 is_success = status_code == 200, and _check_incomplete_experian_pull only builds 'Missing:' when pull_success is False, so that string is reachable ONLY on a non-200; a real no-hit is a 200 and takes the missing_features -> creditGrade=null path that already exists. Sentry EFP-ERRORS-AW is the same issue (460 occurrences since 2025-12-19; Seer root-cause: 401). NEW: 400s are now the majority (16 of 20) and PR #6416 only covers 401/403 - the 400 population needs its own look.
- 2026-08-21T17:54Z [claude-code] 2026-08-21: the literal Experian errorCode/message for the non-200s is not retrievable from any readable source. CloudWatch logs status + response KEYS only (0 hits for errorCode); efp-raw endpoint_transactions carry only our own errorMessages; Sentry EFP-ERRORS-AW breadcrumbs carry the httplib line (status_code 400, reason 'Bad Request') but no body; and bronze COPY INTO for experian_raw_data deliberately stores OBJECT_CONSTRUCT('failure_reason', CASE...) only - 'PII stays unread' - so Snowflake has the same derived string, not errors[]. Only copy is efp-pii, which dpx creds cannot GetObject (403). FIX WITH PRECEDENT: the cashflow branch of the same function (_generate_experian_credit_pull_sql in edgefocus/transformations/bronze/api_events_utils.py) already extracts error text verbatim via $1:productResponse[0]:applicants[0]:exceptionMessage[0]:error_message - adding the equivalent $1:errors extraction for experian_raw_data would surface errorCode/message in bronze.api_events for future pulls without exposing PII. Also from the breadcrumbs: 'No creditProfile found' then 'Experian features missing: 0 total (0 Clarity, 0 other)' - the missing_features dict is EMPTY, which is exactly why _handle_request_v2 takes the complete-failure branch; a real no-hit yields a non-empty missing_features and the creditGrade=null branch.
