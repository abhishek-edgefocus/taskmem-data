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
updated: 2026-08-14T14:55:30Z
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
