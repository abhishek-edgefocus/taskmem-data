---
id: wm-nyjurp
type: task
title: Backfill the northpond slice of silver.api_credit_attributes in PROD (1,294 loans) before the CMOP/BEP crons run
status: next
priority: normal
size: s
tags: [northpond, predictions]
links: [blocked-by:wm-79k8df, parent:wm-3sxcre]
created: 2026-08-24T21:06:38Z
updated: 2026-08-27T13:14:55Z
source: claude-code
---

The new `northpond_api_credit_attributes` transform (DEV-1498, [[wm-79k8df]]) is
stream-driven: a normal tick only processes issuance dates the stream reports as
changed, so on first deploy it picks up new originations and nothing else. The
1,294 historical funded loans (715 TU + 579 Experian) need one explicit
full-history run.

**Order matters.** The two new turndown channels are already registered in
`edgefocus/modeling/predictions/run.py`, so the moment the branch deploys, the
13:30 UTC `--prediction-type curr_mod` cron and the Sunday 14:00 `best_est` cron
will start selecting `northpond_loan_fl` and `northpond_exp_loan_fl`. If the
credit table is still empty for northpond at that point they are no-ops (the
universe IS that table) — harmless, but they will silently produce nothing until
the backfill lands. Run the backfill first.

Run config (Abhishek launches prod jobs himself — [[no-agent-prod-runs]]):

- Dagster asset `northpond_api_credit_attributes`, in the `ingest_api_output`
  job, group SILVER.
- Or directly: `ENVIRONMENT=prod ... python
  edgefocus/transformations/silver/api_events/northpond_api_credit_attributes.py
  --date all`

Expected result, already verified by running the transform's own SQL against PROD
on 2026-08-25: **1,294 rows**, 715 on CHANNEL `northpond_loan_fl` (min AS_OF_DATE
2024-10-09, max 2026-01-12) and 579 on `northpond_exp_loan_fl` (2026-01-20 →
2026-08-24), zero duplicate (EFP_ID, AS_OF_DATE) keys, no null AMOUNT / TERM /
RATE / MONTHLY_PAYMENT / PAYLOAD. Anything materially short of that means the
backfill did not cover full history.

Then confirm the crons produce rows: `silver.predictions` should gain
PREDICTION_TYPE `curr_mod` (and, after the Sunday run, `best_est`) with SOURCE
's3' under both channels for PLATFORM 'northpond'.

Note the DEV run hit a missing `DEV_ABHISHEK.SILVER.API_CREDIT_ATTRIBUTES_STREAM`
— the stream exists in PROD (created 2026-06-25, owner PROD_WRITER) and is
declared in `terraform/snowflake/silver_api_credit_attributes.tf`, so this is a
dev-environment gap only and needs no terraform change.

## Log
- 2026-08-27T13:14Z [claude-code] 2026-08-27: UNBLOCKED — PR #6462 merged 11:27Z and deployed 12:56Z, so this is now the immediate next action and nothing else in DEV-1498 moves until it runs.

ACCEPTANCE NUMBER REFRESHED against PROD at 13:12Z: **1,310 rows**, not the 1,294 quoted in the PR description. The issuance book has grown to 1,365 first-seen loans since the PR was written, so 1,294 would now read as a shortfall. Breakdown: 715 on CHANNEL northpond_loan_fl (AS_OF_DATE 2024-10-09 -> 2026-01-12) and 595 on northpond_exp_loan_fl (2026-01-20 -> 2026-08-25). Zero nulls across AMOUNT / TERM / RATE / MONTHLY_PAYMENT / PAYLOAD, zero duplicate (EFP_ID, AS_OF_DATE) keys. Confirmed PROD.SILVER.API_CREDIT_ATTRIBUTES currently holds zero northpond rows.

Run the `northpond_api_credit_attributes` asset (job `ingest_api_output`, group SILVER) with config `as_of_date: all`. Abhishek launches prod jobs himself.

TIMING: the curr_mod cron is 13:30 UTC daily, best_est 14:00 UTC Sundays. Backfilling before 13:30 gets CMOP the same day; after it, the tick is a harmless no-op and CMOP waits until the next day. best_est additionally needs silver.realized_cashflows_from_origination, which is populated for northpond (11.5k rows / 1,075 loans).

AFTER THE BACKFILL, confirm silver.predictions gains PREDICTION_TYPE curr_mod (then best_est) with SOURCE 's3' under BOTH channels for PLATFORM 'northpond'. Expect roughly 715 loans on northpond_loan_fl and 595 on northpond_exp_loan_fl for curr_mod; best_est will be lower because terminal loans are dropped.
