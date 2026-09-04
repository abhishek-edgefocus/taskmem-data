---
id: wm-d27ypj
type: task
title: Post review comments on PR #6652 (DEV-1754 CL tape union, sanjali)
status: open
created: 2026-09-04T22:38:36Z
updated: 2026-09-04T22:38:36Z
source: claude-code
---

Reviewed head 623a7a6 (edgefocus/transformations/reports/cl_loan_tapes.py, +175/-50, single file, no tests).

11 findings drafted. Top 3 blocking:
1. No overwrite path — build skips any date whose dest key already exists, so the promised backfill cannot replace the already-delivered short tapes (07-31 EOM: 2 loans vs 26). Needs a force/overwrite flag or a documented delete step.
2. _bass_program_rows diverges from the canonical partition in silver/statement_rows/anchored/stmt_positions.py: no UPPER(TRIM()), the isna() fallback is column/value-gated instead of AS_OF_DATE >= BASS_ORIGINATION_ID_CUTOFF, and bass_origination_identifier_validation never runs on this path. Unrecognised labels silently drop from both tapes; NULL post-cutoff labels silently land on the anchored delivery.
3. Partial-day builds: dates come from bronze regardless of which of the two tapes ingested. Bass present + Edge missing writes a short anchored tape, and idempotency freezes it — the DEV-1754 failure mode through a different door.

Also: _warn_if_incomplete has no terminal-state exclusion so it cries wolf once a CL loan pays off; reindex(columns=OUTPUT_COLUMNS) turns servicer schema drift into a blank column in an external delivery; bronze fetch is outside the per-date try and pulls every missing date in one frame; str.contains without na=False; date YYYYMMDD<->ISO round-trip in _warn_if_incomplete; program: str unvalidated; new f-string SQL.
