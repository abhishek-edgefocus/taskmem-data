---
id: wm-u52nd6
type: task
title: Fix Experian OAuth 401 handling in the northpond gateway (DEV-1478)
status: waiting
priority: p2
size: m
waiting_on: samueli-efp, kabeer0022, nakula-efp (PR #6416 review)
nudge: 2026-08-27
tags: [northpond, oncall, api-health]
links: [parent:wm-3y3ckv, relates:wm-9kvv8c, parent:wm-d3qnqe]
refs: [DEV-1478=https://linear.app/edge-focus/issue/DEV-1478/northpond-experian-credit-pulls-intermittently-fail-with-401-oauth]
created: 2026-07-29T13:43:02Z
updated: 2026-08-31T14:36:04Z
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
- 2026-08-21T18:07Z [claude-code] 2026-08-21 CORRECTION to the escalation framing: the Experian failure RATE is flat, not escalating. 30d Logs Insights on northpond_loan_fl/production/gateway (retention 365d): 145,284 pulls, 144,929x200, 290x400, 51x401, 14x500 = 355 non-200 (0.244%); 353 of them produced the 'Missing:' error (350 'credit profile, Clarity report' + 3 'credit profile'). Daily non-200 count rose ~20x (1-5/day in late July to 26-43/day this week) but daily PULL VOLUME rose ~13x over the same window (375-1,163/day 22-29 Jul, to 12,429-13,789/day 18-20 Aug). Rate 22 Jul-4 Aug = 62/20,344 = 0.305%; 15-20 Aug = 141/55,056 = 0.256% - flat to slightly DOWN. So this is a long-standing constant-rate failure whose absolute volume tracks NorthPond's ramp, not a recent regression. Still worth fixing (~0.25% of applicants get a 500 instead of a score) but the urgency is the ramp, not a new break. #6416 covers 51 of 355 (14%); the 290 400s and 14 500s are unaddressed.
- 2026-08-21T21:54Z [claude-code] REBASED ONTO #6425 AND CORRECTED, 2026-08-21. PR #6416 force-pushed (6989356e2, --force-with-lease), title now 'DEV-1478: Re-authenticate and retry once when Experian rejects the NorthPond token'. Still draft.

WHAT LANDED UNDER US: PR #6425 (samueli-efp, merged 2026-08-21 21:41Z, commit 2525b863f, DOPS-695) rewrote get_raw_credit_info to return (body, status_code) instead of (body, status == 200). Direct conflict with our patch -- rebase hit a content conflict, so the fix was rewritten against the new signature rather than merged. Abhishek reviewed and approved #6425 and told the reviewers there 'For context, #6416 is along similar lines and covers the 401s on our side (still WIP)'. #6425's own body names retry-once-on-401 as follow-up, so our PR is the declared continuation, not a duplicate.

TWO CORRECTIONS TO MY OWN EARLIER ANALYSIS (both were wrong in the first PR body, now fixed):
1. I claimed 'every hard failure on 2026-08-19 was the auth path', inferring it from the 0.124s vs 0.887s duration split. That does not follow -- an Experian 400 is also rejected fast, so timing cannot separate 400 from 401. #6425 measured the real split from status codes over 72h: 400x61, 401x11, 500x14. So 401s are roughly an eighth of the hard errors, ~4/day, NOT 27/day. Our fix is worth doing and was explicitly asked for, but it is the smallest of the three buckets; #6425 already moved the 400 majority off the 500 path.
2. The single verbatim 401 I quoted as proof was a CASHFLOW_REQUEST, not a scoring request. Re-cut by requestType: 2026-08-19 had 13,300 SCORING (26 errors, 0.20%) and 132 CASHFLOW (1 error). Cashflow uses a separate Experian account, so it is a genuinely independent instance of the same bug -- both paths are fixed by the same change -- but it is not evidence about the scoring path.
Also corrected: null-creditGrade figure is 705/13,300 scoring = 5.30%, not 836/13,432 = 6.22% (the old number wrongly counted cashflow rows in the denominator and as nulls).

DESIGN CHANGES vs the first version: retry now fires on 401 ONLY (403 dropped -- on this API it means the account is not entitled, which a fresh token does not fix, and a retry bills a second call). Returned status is the final attempt's, so a surviving 401 still raises in _handle_request_v2 and stays visible, which is what #6425's table deliberately preserved. Retry kept in the handler rather than 'in the runner' as #6425's follow-up note suggested, because #6425's review concluded no state should sit on the runner and a handler-local retry holds nothing between requests.

VALIDATION: 595 tests pass across lib/efp/experian_data/ + lib/efp/json_endpoints/ (includes #6425's new cases); 3 of the 9 new handler tests confirmed to FAIL against master 2525b863f; ruff format/check clean, mypy clean. Still unit-tested only -- no Experian UAT exercise.

NOW EASIER: with #6425 carrying the status, the post-deploy 401 count is directly measurable instead of inferred -- that is the proof that takes this out of draft.
- 2026-08-22T07:22Z [claude-code] CI WAS RED ON #6416; TWO FAILURES FOUND, FIXES ARE UNCOMMITTED AND STRANDED ON dpx (2026-08-21 ~22:3xZ).

FAILURE 1 (what CI reported): 'Run Tests' job failed at the 'Run MyPy on legacy codebase (lib/efp)' step -- lib/efp/experian_data/handler_test.py:25: Need type annotation for '_CREDIT_REPORT_BODY' [var-annotated]. Cause: {'creditProfile': [{'riskModel': []}]} has an empty inner list so mypy cannot infer the dict type. My mistake was running mypy on handler.py ONLY; CI runs it over the whole lib/efp tree (1293 files). Fix applied: annotate _CREDIT_REPORT_BODY and _REJECTED_BODY as Dict[str, Any].

FAILURE 2 (hidden behind failure 1, and the worse one): because mypy failed, CI never reached the pytest steps. Running the legacy suite the way CI does exposed a basename collision I introduced -- lib/efp/tu_data/credit_pull/handler_test.py already exists, neither directory has __init__.py, so pytest imports both as top-level module 'handler_test' and errors with 'import file mismatch'. This ABORTS COLLECTION FOR THE ENTIRE LEGACY SUITE, not just my file, on a module I never touched. Fix applied: git mv lib/efp/experian_data/handler_test.py -> experian_handler_test.py (verified unique across the repo). Both files then collect together, 14 passed.
LESSON WORTH KEEPING: for this repo, a new test file must have a repo-unique basename, and 'tests pass' must mean the CI invocation (PYTHONPATH=lib pytest . --ignore=edgefocus/ --ignore=orchestration/), not a per-directory run.

VERIFIED AFTER FIXES: ruff format --check . clean (2632 files), ruff check . clean, mypy over all of lib/efp clean (1293 files). The full legacy pytest run did NOT complete -- ssh dropped mid-run and dpx then became unreachable (connect timeouts on port 22, repeated). So the legacy suite is still UNCONFIRMED on this branch.

CURRENT STATE / PICK UP HERE:
- dpx ~/claude-ws/dev-1478/efp working tree holds both fixes UNCOMMITTED (modified experian_handler_test.py + the rename staged via git mv). Nothing pushed.
- PR #6416 still carries commit 6989356e2, which is RED in CI. It is draft, so nothing is blocked on it, but it must not be taken as green.
- Next steps when dpx returns: (1) run PYTHONPATH=lib pytest . --ignore=edgefocus/ --ignore=orchestration/ to completion, (2) amend/commit the two fixes, (3) push --force-with-lease, (4) watch gh pr checks 6416 through to green.
- 2026-08-22T07:43Z [claude-code] CI GREEN on #6416, 2026-08-22 07:4xZ. Commit a08af60f3 (amended + force-pushed with lease). 'Run Tests' pass in 8m44s (https://github.com/edgefocus/efp/actions/runs/32559795908/job/96999532534), 'Select tests' pass, integration skipped. Both failures from the previous push are resolved: the mypy var-annotated error and the handler_test basename collision (file is now lib/efp/experian_data/experian_handler_test.py).

Full legacy suite confirmed locally before pushing, using the CI invocation: 2,928 passed / 26 skipped, exit 0. Also ruff format + ruff check clean repo-wide (2,632 files) and mypy clean over all of lib/efp (1,293 files).

dpx went unreachable mid-verification and came back 07:24:43Z; the uncommitted fixes survived in ~/claude-ws/dev-1478/efp. Lesson applied: long verification runs on dpx now go out under nohup with a sentinel file, so an ssh drop cannot kill them.

PR body corrected twice over on claims that the CI failures exposed as overstated -- it now cites the full-suite figure rather than the earlier 595 from a two-directory run, and says mypy is clean over all of lib/efp rather than 'on the changed file'.

STILL DRAFT ON PURPOSE. Green CI is not the gate; the gate is deploy-side evidence that the 401s actually stop. Thanks to #6425 carrying the status code that count is now directly measurable rather than inferred from response timing. Re-run the gateway scan on a post-deploy date and compare against the 2026-08-19 baseline on [[wm-rrvgdr]].
- 2026-08-24T12:27Z [claude-code] PR STATE 2026-08-24 (sync sweep) — THE FIX IS DONE AND NOTHING IS MOVING IT. PR #6416 has all checks green (Run Tests SUCCESS, Select tests SUCCESS, integration skipped) and has been untouched since 2026-08-22 07:31Z. It is still isDraft=true with ZERO reviewers requested and zero assignees. mergeStateStatus=BLOCKED is branch protection waiting on an approving review, not a conflict — and no review can arrive while the PR is in draft.

WHY THIS IS THE SHARPEST THING ON THE PLATE TODAY: the 2026-08-20 entry records Abhishek telling Sanjali he would implement DEV-1478 NEXT WEEK. Next week started today, 2026-08-24. The implementation is in fact already written, tested and green; the only thing between it and review is one click.

COMPOUNDING FACT FOUND IN SLACK: in #platform-data-owners on 2026-08-21 02:26 IST Eshan explicitly volunteered — 'Mujhe review assign kar dena I can take a look into them later today!' — after Abhishek asked the channel to look at his three small PRs. Three days later no reviewer has been requested on #6416. A willing reviewer offered and the offer was never taken up; captured separately as its own micro-item.

Independent corroboration that the bug is still live: the efp-agent production API health post for 2026-08-22 (#api-offers-daily, 2026-08-23 19:41 IST) shows northpond_loan_fl at 0% approval, $0 bid, 0 of 6.3K applications — 6.3K applications evaluated and not one approval. That is consistent with credit pulls failing at the auth layer and is worth a glance before deploying, though it is not by itself proof of the 401 path.

NEXT ACTION IS ONE STEP: take #6416 out of draft and request Eshan (and/or Kushagra) as reviewer.
- 2026-08-24T15:50Z [claude-code] 2026-08-24 ROOT CAUSE MEASURED (read-only investigation; PR/branch untouched). The 401 is a CLIENT CLOCK LAG, not a shared/stale token being replayed.

MECHANISM: handler.py sets `self._token_expires_at = time.time() + expires_in` AFTER the OAuth POST returns, but Experian's 1800s runs from when IT issued the token. The client therefore believes every token lives ~0.65s longer than it does. Any credit-report POST landing in that final sliver uses a token Experian has already retired -> 401. The client's own expiry check then trips on the very next request, it mints a fresh token, and service resumes. Failure window per token = exactly the OAuth round-trip time.

EVIDENCE (CloudWatch Logs Insights, northpond_loan_fl/production/gateway, 2026-04-15..08-24, 200,930 Experian POSTs: 200455x200, 383x400, 71x401, 21x500):
1. Dead-window test, Aug 17-22: predicted window = [mint_request+1800, mint_response+1800]. Those windows cover 0.280% of wall clock. 23 of 23 401s fall inside one. 0 of 102 400s do. 
2. 401 inter-arrival times cluster at integer multiples of 1800s: Monte-Carlo p<0.0001. 400s show nothing (10% vs 7% chance).
3. 401s sit immediately BEFORE a mint (median 16s to next mint, 24% within 5s) and NOT after one (6/62 within 60s = baseline). Empirical null from 2,588 successful pulls: 0.59% within 5s. ~41x enrichment.
4. Rate prediction: implied dead window = 1800 * 401_rate = 0.64s. Measured OAuth round-trip = 0.649s median / 0.672s mean (n=723). Predicted rate 0.0373% vs observed 0.0353%.
5. Rate is FLAT across a 30x volume swing (0.031%-0.045%); implied window 0.55-0.81s in every regime. Confirms the 2026-08-21 "flat rate, not escalating" finding by an independent route.

FALSIFIES THE PR'S STATED RATIONALE: "a token retired server-side gets replayed by that worker until its local expiry elapses; every request routed to that worker 401s in ~0.1s until then" is not what happens. 401s are isolated singletons - the very next request always succeeds. A replayed-dead-token model predicts runs of ~100 consecutive 401s per event; zero such runs exist in 131 days.

THE FIX STILL WORKS, but for a different reason than the PR says: it is `_TOKEN_EXPIRY_MARGIN_SECONDS = 60` that does the work (0.65s dead window sits far inside a 60s margin), NOT the retry-on-401. The retry is a safety net. Anyone later "simplifying" the PR by dropping the margin and keeping only the retry would still recover but would burn a second Experian call on every occurrence instead of preventing it. Worth correcting the PR body before review.

RULED OUT with evidence: deploys/container restarts (0 of 71 401s within 1h of a container start; median container age at failure 456h); container identity (401s spread over 6 containers in proportion to lifetime x volume); scaling (ASG ECS-northpond_loan_fl-production is min1/max2/desired1, one t3a.medium, one container at a time since 2026-04-27); time of day (tracks volume shape); request bursts/concurrency (bins containing a 401 average 12.2 pulls/min vs 8.4 overall, but the n-weighted null predicts 12.7 - fully explained by exposure).

TWO CORRECTIONS TO THE INVESTIGATION PREMISE:
- NOT 2 concurrent containers. One container at a time since 2026-04-27 (two concurrent before that). The "2 log streams" in the sample is the 2026-08-18 deploy handover: 37e223ea ran 07-13..08-18 14:48, c21cd773 started 08-18 14:18, overlapping ~30 min.
- There are THREE token-holding objects per container, not two: 2 gunicorn sync workers x the scoring ExperianCreditPull, PLUS the cashflow instances on a separate Experian account (~132 requests/day, irregular mints). That third lattice is what corrupts any BACKWARD-looking token-age calculation. The earlier "median token age ~475s, only 1 of 57 near expiry" result is an artifact: the empirical null median for time-since-previous-mint is 445s, i.e. that number was the population baseline, not a measurement of the failing token. Looking FORWARD to the next mint is the correct attribution-free measurement.

The 21x 500s are unrelated: two tight Experian-side clusters (2026-05-08 00:52-01:12, 2026-08-18 19:20-21:18), not deploy-adjacent.

Grafana note: the dashboard efp-production-traffic/production-traffic-endpoint-lb is on grafana.sterling.edgefocuspartners.com, which rejects the ~/.grafana.env creds (those are for grafana.edgefocuspartners.com, which has no such dashboard). Went to the underlying source instead - it is an ALB target-group view; all of the above came from CloudWatch directly.
- 2026-08-24T16:02Z [claude-code] READY FOR REVIEW 2026-08-24. PR #6416 out of draft, CI green on 9abdf213b ('Run Tests' pass 7m26s, https://github.com/edgefocus/efp/actions/runs/32747337962/job/97495901987). Title: 'DEV-1478: Re-authenticate and retry once when Experian rejects the NorthPond token'. 2 files, +366/-29.

ACTED ON THE EXTERNAL REVIEW (~/pr-6416-review.md). Four of five findings verified and applied:
- BLOCKING BUG FIXED: a failed re-authentication inside the retry raised out of get_raw_credit_info. Verified the chain myself -- credit_pulled_channel.py:199 wraps ANY exception into ExperianCreditPullErrorException, northpond_loan_fl_channel.py:628 catches it and returns NorthPondResponse_Error (soft envelope, no 500, no Sentry). So the change silenced exactly the credential-revocation case. Now caught: log + report the original 401. New test test_a_failed_reauthentication_reports_the_original_rejection, confirmed failing without the guard.
- Removed the retry-layer paragraph: verified _experian_pull_runner is typed Optional[ExperianCreditPull] at credit_pulled_channel.py:50, so 'the runner' IS this handler class and #6425's follow-up note was already satisfied. The paragraph invented a disagreement.
- Removed the thread-safety hedge: verified devops/endpoint/aws_cdk/deploy/stack.py:151 runs 'gunicorn -w{WORKERS}' with no -k and no --threads (sync worker), northpond_loan_fl workers=2 max_capacity=2. My earlier grep missed this only because I truncated output at head -20.
- Softened both 403 comments to claim only that 403 has never been observed on this endpoint (previously asserted an unsourced vendor semantic).

REJECTED THE REVIEW'S HEADLINE FINDING, with evidence. It claimed the root cause is token-expiry boundary lapse -- 'all 57 401s at token age 1799.24-1800.71s'. I re-ran their CloudWatch query: aggregates match (4,008 mints vs their 4,005; 57 401s; expires_in=1800 on all mints) but the correlation does not -- token age at 401 came out min 7.41s, median 475.06s, max 1800.12s, with only 1 of 57 in [1790,1810]. Both computations are unsound anyway: the log group has only 2 streams (one per container) with multiple gunicorn workers writing to each and NO pid/worker field in the log line -- median gap between consecutive mints within one stream is ~500s where a single worker on an 1800s TTL would show ~1800s. A 401 cannot be attributed to the mint that served it from what is logged today. Root cause therefore still OPEN; moved to a separate session per Abhishek.

PR NARRATIVE now claims no outcome: all 'drops to zero' and cross-process-retirement language stripped from both the PR body and the commit message. Framing is 'the recovery path was incorrect, this makes it correct', with an explicit note that the mechanism is unestablished and that the post-deploy rate cannot be modelled from current logging. The new warning line 'discarding the cached token and retrying once' is named as the thing that will actually count rejections.

VALIDATION before push: ruff format 2,632 files clean, ruff check clean, mypy clean over 1,293 files, pytest 2,929 passed / 26 skipped.

NOT DONE, deliberately: no Experian UAT exercise (unit-tested only, stated in the PR); review's optional suggestion to replace private-name monkeypatching with the URL-routing post stub from credible_loan_fl_tare_test.py not taken -- would also cover __get_access_token's expires_in parsing, worth doing if a human reviewer asks.

NEXT: Abhishek to request reviewers (see [[wm-f7egzv]] -- Eshan offered).
- 2026-08-24T16:49Z [claude-code] ROOT CAUSE FIX FOLDED IN AND SHIPPED 2026-08-24. PR #6416 open, ready for review, CI green on 55b4e08c4 (Run Tests pass 8m30s, Select tests pass, Seer Code Review pass, integration skipped). Title now 'DEV-1478: Stop crediting the Experian token with its own round trip, and recover from rejections'.

THE CAUSE, measured by a separate session and now fixed here: __get_access_token set _token_expires_at = time.time() + expires_in AFTER the OAuth response was parsed. Experian counts expires_in from when IT issued the token, so the deadline was credited with the round trip the token had already spent -- every token believed to live ~0.65s longer than it did. Requests landing in that sliver used an already-retired token and got 401. Evidence: dead windows are 0.28% of wall clock, 23 of 23 sampled 401s fall inside one, 0 of 102 400s do.

THE FIX: requested_at = time.time() captured BEFORE the OAuth post; _token_expires_at = requested_at + expires_in - _TOKEN_ISSUE_SKEW_SECONDS (5s, covering clock difference vs Experian and issue-side latency).

NOTE FOR REVIEWERS, stated in the PR so nobody has to ask: the 60s _TOKEN_EXPIRY_MARGIN_SECONDS refresh margin already in this PR would ALSO have kept requests out of the dead window on its own. It is kept because it does a different job (protects a request already in flight), but the stored deadline is now correct in itself rather than relying on a read-side margin to absorb an error it does not model. Combined cost ~3.7% more OAuth calls against the 1800s TTL.

NEW TEST test_the_token_deadline_excludes_the_oauth_round_trip drives the REAL __get_access_token through a URL-routing stubbed token endpoint with a simulated 0.30s round trip, asserting the deadline sits within token_request_time + expires_in - skew. Confirmed failing when only the anchoring line is reverted. It also covers expires_in parsing, which the external review had flagged as untested -- so that review point is now closed too.

This supersedes the earlier 'root cause not established' framing: the PR body now leads with the cause and the evidence, and states that closing the window should remove the failure mode rather than reduce it, with the retry warning line as the signal that would reveal a second mechanism.

VALIDATION before push: ruff format 2,632 files clean, ruff check clean, mypy clean over 1,293 files, pytest 2,930 passed / 26 skipped. 11 handler tests, 5 of them confirmed failing against master 2525b863f.

DONE HERE. Remaining on this item is human-side: request reviewers ([[wm-f7egzv]], Eshan offered), then merge and watch the warning line after deploy.
- 2026-08-24T17:00Z [claude-code] 2026-08-24 VOLUME TREND CHECKED (Abhishek asked whether the issue has recently reduced). IT HAS NOT. The apparent drop is the weekend trough plus a part-day.

NOTHING IS DEPLOYED: container c21cd7738c5c (started 2026-08-18 14:18Z, release 622bb331e) is still the live one as of 2026-08-24 16:57Z. No redeploy since 08-18, so neither #6416 (draft) nor #6425 (merged 08-21 21:41Z) is in production. Any change in the error curve cannot be either of them.

RATE IS UNCHANGED: baseline 2026-05-25..08-17 = 126,033 pulls / 40x401 = 0.0317%. Recent 08-18..now = 67,125 pulls / 26x401 = 0.0387%. Expected 21.3 at baseline rate, observed 26, Poisson z=+1.02 -> not significant. The 401 rate has been flat for three months; 401 VOLUME is just rate x pull volume.

WHAT THE "DECREASE" ACTUALLY IS: 08-18 Tue 13,789 pulls / 43 non-200 (the peak, and it carried the 14 anomalous 500s) -> 08-22 Sat 6,422 -> 08-23 Sun 5,165 -> 08-24 Mon 5,164 BUT that is only to 16:57Z, i.e. 71% of the day; full-day equivalent ~7,300, which is in line with last Monday's 7,653. Same-weekday comparison shows no decline at all.

DIRECTION IS UP, NOT DOWN. Weekly pulls: 11,255 (w/c 07-27) -> 31,566 -> 43,490 -> 69,614 (w/c 08-17). Weekly 401s: 7 -> 12 -> 9 -> 29. Weekly non-200s: 37 -> 67 -> 111 -> 167.

EXPECTATION AFTER THE FIX -- and this is the part worth setting straight before anyone reads the error graph as a success metric:
- 401s from this mechanism go to ~0. The dead window is 0.65s; _TOKEN_EXPIRY_MARGIN_SECONDS=60 is a ~92x safety factor. 23 of 23 attributable 401s over Aug 17-22 were this class.
- BUT 401s are only ~17% of non-200s. At last full week's volume (9,945 pulls/day) the visible error count goes from ~24/day to ~20/day. The 400s (~20/day, 80% of the surface) are untouched by #6416 -- #6425 moved them off the HTTP 500 path but they are still failed pulls.
- So the correct post-deploy proof is the 401 COUNT specifically (now directly measurable thanks to #6425 carrying the status code), NOT total error volume, and it must be normalised per-pull and compared same-weekday. A raw before/after on the error graph will be dominated by the volume ramp and the weekly cycle.
- Residual 401 risk after the fix is a different class: the 2026-07-12/13 "account is in invalid state" burst (279 requests) was a credential/account problem. Neither the margin nor the retry prevents that one -- re-auth would fail too.
- 2026-08-26T13:10Z [claude-code] OUT OF DRAFT AND NOW GENUINELY WAITING ON OTHER PEOPLE — status moved next -> waiting 2026-08-26. PR #6416 was taken out of draft on 2026-08-24 19:32Z and retitled 'DEV-1478: Stop crediting the Experian token with its own round trip'. All four checks green (Run Tests, Select tests, Seer Code Review SUCCESS; integration skipped). Three reviewers requested: samueli-efp, kabeer0022, nakula-efp. Linear DEV-1478 is In Review, High — and is the ONLY issue of his sitting in In Review, so nothing else is competing for the same attention.

ZERO REVIEWS SUBMITTED IN TWO DAYS. reviews[] is empty; mergeStateStatus=BLOCKED is branch protection waiting on an approving review. So the thing I flagged on 2026-08-24 (green fix invisible in draft) is fixed — the ball is now in the reviewers' court, not his, which is why this is waiting rather than next. Set nudge=2026-08-27: if no review has landed by then, chase in #platform-data-owners, where he already has a live reviewer-swap thread from 2026-08-21.

Worth remembering when chasing: Sanjali chased HIM on this on 2026-08-20 and he committed to shipping it this week. The code has been ready since 08-21; only review latency is left.
- 2026-08-27T17:17Z [claude-code] DEPLOYED TO PRODUCTION 2026-08-27. Jenkins 'Endpoint - NorthPond / Production - Model and Gateway Task' build #64, Finished: SUCCESS, total 1384.76s.

WHAT SHIPPED: gateway = 662f8db57c36be0d8fc8fc4716c555ab52dc56e7 (master HEAD at deploy time; our merge b9503fa62 verified as an ancestor, and the handler at that commit confirmed to contain requested_at = time.monotonic(), _TOKEN_REFRESH_BUFFER_SECONDS = 65, _TOKEN_REJECTED_STATUS = 401). Model UNCHANGED at b04ca1f63 -- log line 'b04ca1f63... already present in ECR', so the ERROR-1231 stale-model trap was avoided. Launch template v61 -> v62.

ROLLOUT: new instance i-01e90004b90d04bf1 added 16:55:44Z, SUCCESS signal 17:12:29Z (17 min of the 35 min PT35M budget), old instance i-056d7ea8af704b40b terminated 17:12:31Z, stack UPDATE_COMPLETE 17:12:35Z. Zero customer impact: HTTPCode_ELB_5XX_Count and HTTPCode_Target_5XX_Count both returned NO datapoints across the window, and RequestCount per 5min ran 89/85/90/74/90/95 straight through the swap.

HEALTH-CHECK PROGRESSION during cold load (useful for the next deploy, it looks alarming and is not): Target.FailedHealthChecks -> Target.Timeout -> Target.ResponseCodeMismatch -> healthy. The Timeout phase is CPU starvation on a t3a.medium (2 vCPU running 2 gateway + 2 model gunicorn workers while the model loads artifacts).

CORRECTION I MADE MID-DEPLOY: I raised a possible traffic-gap alarm on seeing new=unhealthy + old=draining in one poll frame. That was a stale 30s frame. CFN proves the ordering was correct -- SUCCESS signal at 12:12:29 preceded termination at 12:12:30, and that signal only fires after the instance's own user-data loop gets 200 from /server-status.

ALSO CORRECTED: I had flagged the 4 CVE dependency bumps as the highest-risk part of this deploy. The Docker build shows Steps 7-16 ALL 'Using cache', including COPY requirements.txt and pip install. Only Step 17 (COPY repo-code) changed. The runtime environment is byte-identical to the previous image, so that risk did not materialise -- but it also means those CVE bumps may not actually be in the running image. Worth a separate check.

BASELINE (24h pre-deploy, captured 16:36:30Z): Experian 200=13,360 / 400=20 / 401=4 / 403 absent; token mints 151/day; retry warnings 0. First 20 min post-deploy: 200 x 329, 4 mint/retry-class lines, zero 401s -- far too early to mean anything.

STILL TO VERIFY (the actual point of the PR): 401 count should go to ~0 against the 4/day baseline, and the new warning 'discarding the cached token and retrying once' should stay silent. If it fires steadily, a second mechanism retires tokens and the round-trip diagnosis is incomplete. Give it 24h. Also confirm the null-creditGrade rate holds at ~5.30% of scoring (705/day on 2026-08-19) -- a move there would indicate one of the other 413 commits broke something.

REVERT (still valid): same Jenkins job, gateway_branch=622bb331e42037f41439db450da89e3b493887c1, model_tag=model_northpond_exp_20260701_191417_UTC. Both images still in ECR, no lifecycle policy.
- 2026-08-31T14:36Z [claude-code] POST-DEPLOY VERIFICATION COMPLETE 2026-08-31, four days after the 08-27 deploy. THE FIX WORKS. Safe to close DEV-1478.

401s PER DAY (gateway log group): 08-24=5, 08-25=2, 08-26=8, 08-27=1, then 08-28/29/30/31 = ZERO. Sixteen in the four days before, none in the four days since. The last 401 ever recorded is 2026-08-27 14:01:10Z -- three hours eleven minutes BEFORE the deploy completed at 17:12:35Z.

THE RETRY PATH HAS NEVER FIRED. Zero 'discarding the cached token and retrying once' lines in eight days. That is the ideal result twice over: the anchoring fix closes the window so completely nothing reaches the retry, AND it rules out a second mechanism retiring tokens, which was the open question. The round-trip diagnosis is confirmed complete.

3-day status mix post-deploy: 200=22,305, 400=47, no 401 row, no 5xx row, zero ERROR/Traceback/Exception lines.

TOKEN MINTS: pre-deploy 134/134/146/150, post-deploy 140/133/129. I predicted +3.7% from the 65s buffer; the series varies +-12% day to day so a 3.7% change is not resolvable in this data. Call it unchanged within noise rather than confirmed.

THE 08-28 NULL SPIKE -- INVESTIGATED, NOT OURS. Null creditGrade by day: 08-24=4.37%, 08-25=5.90%, 08-26=6.76%, 08-27=6.91% (deploy day), 08-28=22.77%, 08-29=8.03%, 08-30=5.23%, 08-31=9.64%. One-day excursion that resolved itself.
Abhishek hypothesised it was Samuel's #6425 (merged and shipped in the same image) changing how incomplete pulls are classified. The missing-feature anatomy disproves that:
  08-26 (pre):   76 nulls -> both bureaus 50, clarityReport-only 21, creditReport-only 5
  08-28 (spike): 206 nulls -> clarityReport-only 164, both 35, creditReport-only 7
  08-30 (post):  48 nulls -> both 31, creditReport-only 9, clarityReport-only 8
The spike lives almost entirely in ONE bucket (clarityReport-only: 21 -> 164 -> 8) while the other buckets barely move. Every null response carries an identical key shape on all three days (applicationUuid, creditGrade, experianMissingFeatures, requestUuid, timestamp), so there is no classification change. A code-path change would shift all buckets together and would persist; this is an Experian-side Clarity availability problem on 2026-08-28.
NOTE FOR [[wm-ufw7kj]] / DEV-1490: null rate tripled for a full day and NOTHING alerted -- no exception, no Sentry event, HTTP 200 throughout. That is the strongest argument yet for putting monitoring on this path.

FIRST FULL POST-DEPLOY WEEKDAY sanity: errors 0.00-0.34% across all days, unchanged from the 0.17% pre-deploy baseline. Applications flowing, scores generated across the full grade range.

REMAINING (not blocking DEV-1478): the four CVE dependency bumps may not be in the running image -- Docker Steps 7-16 all came from cache, so the runtime env is byte-identical to the pre-deploy image. Worth a separate check with Victor.
