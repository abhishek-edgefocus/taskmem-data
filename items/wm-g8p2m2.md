---
id: wm-g8p2m2
type: task
title: Land PR #6277 (Nelnet feeds end to end) before Oliv's Monday cutover
status: next
priority: p1
size: s
due: 2026-08-16
people: [Abhijeet]
tags: [northpond, edgex, nelnet]
links: [parent:wm-gj5tkx, blocks:wm-3vkbn9]
refs: [PR6277=https://github.com/edgefocus/efp/pull/6277, DEV-1481=https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction]
created: 2026-08-14T13:52:29Z
updated: 2026-08-14T20:31:59Z
source: claude-code
effort: <1h
label: Nelnet PR merge
---

PR https://github.com/edgefocus/efp/pull/6277 "DEV-1481: Ingest Oliv's Nelnet servicer feeds end
to end" is the single gating step for [[wm-gj5tkx]]. Oliv are targeting Monday 2026-08-17 to start
dropping the PII-free `olivfinancial_loan_YYYYMMDD.csv` / `olivfinancial_transaction_YYYYMMDD.csv`
files. If this is not merged and deployed by then, the new files land in S3 with no parsing rule
that matches, sit at STATUS='unknown' in PROD.BRONZE.STATEMENT_FILES, and the first days of the
new feed have to be replayed.

STATE AS OF 2026-08-14: OPEN, 13 files +915/-27, base master, branch
abhishek/dev-1481-nelnet-positions. mergeStateStatus BLOCKED — that is branch protection waiting
on an approval, not a merge conflict. reviewDecision REVIEW_REQUIRED and no human has looked at it
since it was opened on 2026-08-13; the only review on record is Sentry's bot. Its one HIGH finding
(LAG() nested inside LAST_VALUE() in `_NELNET_POSITIONS_PROJECTION`, which Snowflake rejects) was
fixed in head commit 113fd3a and the bot marked it resolved.

This PR is the consolidation of the two earlier stacked PRs; #6262 was closed as superseded. It
carries both feeds bronze-through-standardized, the parsing rules for the new names, ignore rules
for the superseded VELOCITY/xlsx keys, and the two terraform table declarations.

Today is Friday 2026-08-14, so the review has to be asked for today to be safe — the nominal due
date below is the day before the cutover, but nobody will review it over the weekend.

## Next steps
- Request review on #6277 from whoever is closest to the northpond silver layer (Abhijeet reviewed
  the recent northpond PRs #6208/#6209).
- Once approved, merge and confirm the parsing rules are live in prod before Monday's drop.
- After the first real file lands, check PROD.BRONZE.STATEMENT_FILES for STATUS on the two new
  keys, and confirm the transaction export no longer carries `Last Name` (the one PII claim from
  Nate that is still inferred rather than verified — see [[wm-8a5pwn]]).

## Links
- PR: https://github.com/edgefocus/efp/pull/6277
- Ticket: https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction
- Parent work item: [[wm-gj5tkx]]

## Log
- 2026-08-14T13:52Z [claude-code] Created 2026-08-14 during the intake sweep. Inferred from the Nate DM (naming and Monday go-live locked 2026-08-14 01:33-02:05 IST) plus the GitHub state of #6277 — the PR has had no human review since it opened and the cutover is three days out.
- 2026-08-14T20:10Z [claude-code] Reviewed the branch while writing ~/notes/northpond/02-standardized-mapping.md. Two things worth a check before/at merge: (1) the Nelnet transaction bridge is an INNER join on issuance_v2.SERVICER_LOAN_NUMBER, so unbridged rows are held back silently - count Nelnet transaction rows vs rows surviving the bridge after Monday's cutover; (2) STATE / INCOME / ORIGINATION_FEE_PCT / FIRST_PAYMENT_DUE_DATE still come only from issuance v1 joined on the numeric loan id, so confirm v1 issuance still lists Nelnet-serviced loans or those four go NULL for the whole EDGEX book.
- 2026-08-14T20:31Z [claude-code] Ran a full code review of PR #6277 at head 131a4e85b (13 files + 2 md tests). 10 findings, none blocking merge mechanically but two worth fixing before Monday: (1) rate-scale mismatch - the Nelnet feed ships INTEREST_RATE/CURRENT_APR as decimal fractions (0.199/0.215 in the PR's own md fixture) while positions.py and transfers.py divide by 100 as they do for FCC's percent-scaled tape, so every Nelnet loan would land in silver.positions with INT_RATE/APR 100x low and a wrong actuarial REMAINING_TERM; (2) the new investor arm reads silver.northpond_stmt_issuance_v2 from four stmt assets (positions, transactions, nelnet_positions, purchase_tapes) but none declares a Dagster dep on northpond_stmt_issuance_v2, so they can materialize before it and freeze a wrong FUND for the day. Also: charge-off date/principal are erased once a Nelnet loan leaves 'charge off' (the ChargedOff->PaidOff case that NORTHPOND_PAID_OFF_OVERRIDE_LOANS exists for); a loan whose first row is already 'charge off' gets a fabricated date and NULL principal; stored FUND is never re-derived so Oliv's promised current_investor backfill to 2026-08-11 will not reattribute existing rows; unmapped Nelnet statuses now fail the shared northpond_positions asset and take the FCC leg down too. Plus stale comments: stmt_nelnet_positions.py and stmt_nelnet_transactions.py still claim as_of_date_offset=-1 on the transaction rule (113fd3a removed it), the northpond_assets.py nelnet comment contradicts its own deps list and is duplicated, and statements_northpond.py still names the now-ignored CLEANED.xlsx as the nelnet transactions source.
