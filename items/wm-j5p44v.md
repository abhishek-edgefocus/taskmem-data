---
id: wm-j5p44v
type: task
title: OpenRoad pre-tape history: run the bronze backfill, don't derive or seed it
status: next
priority: high
tags: [openroad, backfill, bronze]
created: 2026-08-21T17:33:45Z
updated: 2026-08-21T17:33:45Z
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
