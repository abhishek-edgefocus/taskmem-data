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
refs: [PR6277=https://github.com/edgefocus/efp/pull/6277, DEV-1481=https://linear.app/edge-focus/issue/DEV-1481/ingest-olivs-nelnet-servicer-files-loan-transaction]
created: 2026-08-14T13:52:29Z
updated: 2026-08-14T13:52:35Z
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
