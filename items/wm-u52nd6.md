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
updated: 2026-08-24T12:27:55Z
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
