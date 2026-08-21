---
id: wm-j5p44v
type: task
title: OpenRoad pre-tape history: run the bronze backfill, don't derive or seed it
status: next
priority: high
tags: [openroad, backfill, bronze]
links: [blocked-by:wm-85nuv4]
created: 2026-08-21T17:33:45Z
updated: 2026-08-21T19:30:23Z
source: claude-code
estimate: half-day
---

Read-only investigation 2026-08-21. Answers "how do we fill OpenRoad history before
the tape starts 2026-06-29" — and the answer is that there is no history gap. The
data is in efp-raw and has never been loaded.

EVIDENCE
- s3://efp-raw/statements/openroad/ holds 1,127 daily LoanTape files, 2023-07-20 ->
  2026-08-19, ZERO missing days (verified month-by-month count). Plus 1,102
  Payments_Edge_Orl_ files back to 2023-08-14.
- PROD bronze.statement_files, platform=openroad:
    positions      52 files  2026-06-29..2026-08-19   <- 1,075 files never loaded
    payments       52 files  2026-06-29..2026-08-19
    purchase_tape  33 files  2023-07-13..2024-12-14   <- FULLY backfilled
  Same platform, same bucket: the purchase tape backfill was run, the loan tape's
  was not.
- WHY 2026-06-29: that is the merge date of f60cb199a "DEV-1150: Ingest OpenRoad
  statement files (loan tape, payments, transactions)" (PR #5640), which added the
  openroad_loan_tape parsing rule. SQS matched arrivals from that day forward; the
  one-off S3 backfill was never run. The rule's own docstring already covers the
  older LoanTape_Edge_ prefix "through 2023-07-23".

NO CODE CHANGE NEEDED
- Schema is 67 cols and stable from 2023-10-01 on; only Jul-Sep 2023 files are
  narrower (58-59 cols, 1-4 loans). openroad_stmt_positions.COLUMNS references NONE
  of the 10 later-added columns (Name, credit_score, purchase_*, refinance_flag), and
  FUND is a hardcoded constant (openroad_constants.OPENROAD_FUND = efhyf), so even
  the narrowest 2023 files parse cleanly.

PRECEDENT: ANCHORED, THE OTHER FOURSIGHT PLATFORM
  Foursight delivers the identical file family to both prefixes. anchored's
  LoanTape_Edge_Anchored_ series is ALSO 1,127 files starting ALSO 2023-07-20.
  bronze/silver anchored positions = 1,127/1,128 days from 2023-07-20. It was
  backfilled (PR #5428 bronze, PR #5576 silver, DEV-1152). OpenRoad is the only one
  of 12 platforms in silver.positions whose history does not reach its book.

CONSEQUENCE FOR DEV-1539 / PR #6413 ([[wm-ay9uu3]], [[wm-ggzjhb]])
  openroad/constants.generate_derived_status derives fully_paid from the daily
  balance. With the history loaded, all 13 censored payoffs are OBSERVED, not
  inferred. The seeded-13-constants proposal and the closing-payment fallback both
  become unnecessary. Do this BEFORE landing #6413.

ORDER: blocked on [[wm-85nuv4]] (the silver chain has not run since 2026-07-07 —
backfilling bronze under a dead chain achieves nothing).

HOW: statement_file_ingestion Dagster asset, mode=backfill, platform=openroad,
backfill_environment=prod (orchestration/assets/statement_file_assets.py:149).
CLI equivalent: ingest_statement_files.py backfill --platform openroad --env prod
(supports --dry-run, --filter, --limit). He launches prod runs himself.

## Log
- 2026-08-21T19:30Z [claude-code] 2026-08-21 DRY RUN PASSED — Dagster run 983c6a8b-6e16-4be1-99d6-8c0fde63d027 (ingest_statement_files, manual, all dry_run:true), SUCCESS 5/5 in 34.7min. statement_files: 1834 would-insert / 320 would-update / 138 skipped = 2292 files, matching the S3 prefix count exactly. CORRECTION to this item's earlier numbers: bronze.statement_files already held 458 rows under statements/openroad/, not 137 — 321 sat as status='unknown' PLATFORM=NULL (SQS-registered before the rule existed); the earlier query filtered PLATFORM='openroad' and missed them. Substance unchanged: none of that history is in statement_rows. Files that become pending after the real run = 1834+320 = 2154, as predicted. Only 1 file stays 'unknown' (a zero-byte *_Edge_Orl*.csv literal-glob upload from 2026-08-11) — so the parsing rule DOES match the whole series including the four pre-rename LoanTape_Edge_ files of 2023-07-20..23. TIMING CORRECTION: not 'minutes'. statement_rows burned 19m39s with 0 files because _run_removed_file_cleanup (ingest_statement_rows.py:516) takes no platform arg — the platforms:[openroad] filter scopes only ingestion, so ~20min is fixed cost every run. Budget ~1h for the real run; ~2 scheduled */30 ticks will skip (skip_if_running), delaying other platforms' SQS pickup by up to an hour. Next: rerun same config with the five dry_run flipped to false.
