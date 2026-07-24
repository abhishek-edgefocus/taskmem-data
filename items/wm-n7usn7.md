---
id: wm-n7usn7
type: task
title: Ingest Oliv legacy purchase file at new SFTP path (purchase_file_legacy/) — BLOCKED on grain semantics
status: review
priority: p1
size: s
people: [Nate]
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-embhpy]
created: 2026-07-24T08:02:53Z
updated: 2026-07-24T09:10:04Z
source: claude-code
---

Oliv is moving the legacy-format purchase tape to a NEW SFTP folder: `purchase_file_legacy/YYYY/MM/purchase_file_legacy_{date}.csv` (Nate, 2026-07-23 23:26 IST). The new standardized purchase file goes to a separate `purchase_file/` folder — NOT ingested for now (option 2a agreed). Abhishek committed in-thread: "I will add this to our parsing logic."

## Code scope (small — ~30 lines, 1 file)
- `edgefocus/transformations/bronze/parsing_rules/northpond.py`: add ONE ParsingRule — pattern `s3://.*/statements/northpond/purchase_file_legacy/\d{4}/\d{1,2}/purchase_file_legacy_(?P<date>\d{8}).*\.csv`, date fmt `%Y%m%d`, `file_config=S3CsvFile()` (existing rule is S3XlsxFile), `statement_type="purchase_tape"`, `account_name="northpond_efhyf"`.
- SFTP sync: NO CHANGE NEEDED — `edgefocus/sftp/northpond.py` is a whole-tree mirror with only an exclude list. VERIFIED: dummy already auto-landed at `s3://efp-raw/statements/northpond/purchase_file_legacy/2026/07/purchase_file_legacy_20260723.csv` (107,134 B, 2026-07-23 18:36).
- silver `stmt_purchase_tapes.py`: NO CHANGE — dummy header is an EXACT 21-col match to the ColumnDef source names. loan_id is OLV-prefixed (OLV12562550) as expected.
- `lib/efp/stats/datastores/northpond/statement_purchase_tape.py`: leave alone (deprecated datastore path, xlsx-only from efp-derived/trades/northpond_ff).

## BLOCKERS (not just clarifications)
1. **GRAIN MISMATCH — the central blocker.** Prod today = 6 files / 6 purchase EVENTS (62,46,47,60,98,59 loans; sum=372=total distinct loans), each loan appears exactly ONCE, PURCHASE_DATE == AS_OF_DATE == true purchase date. Nate's dummy = 589 loans in ONE file, ALL stamped purchase_date=2026-07-23 (the file date), funding_dates spanning 2024-07-02 -> 2025-11-20. Overlap vs prod: 334 already have purchase-tape rows, 255 new, 38 prod loans absent. So it is NEITHER a clean incremental event file NOR a clean full-book snapshot. Ingested as-is it re-books 334 loans under a WRONG purchase_date and destroys the true one; if dropped daily that is 589 rows/day (~215k/yr) vs 372 rows total today. Corrupts at-purchase features (int_rate_at_purchase, see wm-gxykru/DEV-503) and TAPE_PRINCIPAL/TAPE_PRICE via transfers.py. NEED NATE TO STATE: (a) incremental per-purchase-event or rolling book snapshot? (b) is purchase_date the true purchase date or the file generation date?
2. **DUMMY DATA AT THE PROD PATH.** Nate: "pay little attention to the values" + "let me see if we can generate some regular dummy legacy purchase files in real time". Fabricated files are landing on the exact prefix we would ingest from. Do NOT enable the rule until either a real-file cutover date is agreed or dummies move to a separate staging prefix.
3. **NO CUTOVER/DEDUP PLAN vs the old xlsx.** Old rule (`purchase_tape/Pool N ... MMDDYYYY.xlsx`, mirrored from efp-derived/trades/northpond_ff by mirror_trade_files.py) is still live and writes the SAME statement_type='purchase_tape'. If Oliv sends both during transition -> double count. Need a cutover date or a distinct statement_type.

## Lower-risk items
- BOOLEAN encoding: is_home_owner/modified are BOOLEAN in silver; xlsx gave real booleans, CSV gives unquoted 0/1. Snowflake `0::BOOLEAN` -> FALSE so likely fine, but verify in backfill.
- account_name hardcoded 'northpond_efhyf'; Nate warned filenames/folders will change "as we enter into more programs".
- Existing purchase_tape rule has NO MonitoringSchedule (event-driven). If the legacy file becomes daily, add Frequency.DAILY.

## Next steps
1. Ask Nate the two grain questions (incremental vs snapshot; purchase_date semantics) — BLOCKING, code cannot ship correctly without it.
2. Agree a cutover date + confirm dummies stop / move off the prod prefix.
3. Then add the parsing rule + test + backfill.

## Log
- 2026-07-24T08:08Z [claude-code] 2026-07-24: Abhishek states Nate confirmed the purchase tape carries only INCREMENTAL loans with no dupes — which matches existing pipeline semantics (one file per purchase event, each loan once). Verified against the full C0BJ1M304BU thread (2026-07-22 16:22 -> 2026-07-23 23:44) and the 07-16 call notes: the only 'superset of loans' statement is Nate 2026-07-22 17:16 point 2b, and it is about the ISSUANCE_V2 file, NOT the purchase tape. No incremental/no-dupes statement for the purchase tape found in Slack or call notes — Abhishek may have it from a call not captured here. IF incremental is correct, BLOCKER 1 (grain) is CLOSED and the dummy's 589 rows / 334 overlap with prod is just fabricated noise per Nate's 'pay little attention to the values'. Remaining work is unchanged: ~30-line parsing rule, no silver change. Also per Abhishek: the dummy file is for DEV_ABHISHEK testing only and Oliv will be asked to remove it afterwards — note that deleting the S3 object does NOT retract already-ingested bronze/silver rows (no delete reconciliation on the S3 statement path, unlike the google_sheet ingesters), so dummy rows must be purged manually.
- 2026-07-24T09:10Z [claude-code] 2026-07-24: IMPLEMENTED on repos-3 (dpx), branch abhishek/dev-1474-ingest-northpond-purchase-tape-from-new-sftp-path off origin/master 259a27e90, commit cc5e913e7. Linear DEV-1474. NOT pushed, no PR yet.

CHANGES (2 files, +113): (1) edgefocus/transformations/bronze/parsing_rules/northpond.py — new ParsingRule 'northpond_purchase_tape_legacy_csv', pattern s3://.*/statements/northpond/purchase_file_legacy/\\d{4}/\\d{1,2}/purchase_file_legacy_(?P<date>\\d{8}).*\\.csv, %Y%m%d, S3CsvFile(), statement_type=purchase_tape, account_name=northpond_efhyf, priority=1; header inventory comment updated. (2) NEW edgefocus/transformations/bronze/northpond_patterns_test.py — 6 tests.

KEY DESIGN CALL: used the ParsingRule 'priority' field (supersession on platform+statement_type+as_of_date+account_name) — priority=1 on the csv rule vs default 0 on the Pool N xlsx rule. This resolves the earlier cutover double-count worry WITHOUT needing a separate statement_type: if both land for the same as_of_date the csv wins. Note they only collide when as_of_dates coincide.

VERIFIED: ruff format+check clean; mypy clean; new tests 6/6; bronze parsing suite 92 passed; orchestration/tests/bronze_statement_file_arrival_test.py 49 passed. End-to-end read of the REAL delivered file through rule.file_config.fetch_datasets: 589 rows, 21 cols, all 21 silver-read columns present, 0 missing, 0 extra, 0 null loan_id, loan_id OLV-prefixed. Negative test confirms the future purchase_file/ standard file does NOT match any rule.
BOOLEAN RISK CLOSED: S3CsvFile reads dtype=str so is_home_owner/modified arrive as '0'/'1'; confirmed in Snowflake that '0'::BOOLEAN=False and '1'::BOOLEAN=True, so the silver BOOLEAN cast is safe.

REPO STATE: repos-3 prior work parked on branch wip/repos-3-parked-20260724 (commit 6205bd0d9 = the uncommitted lib/efp/snowflake.py fetch_pandas_all fallback). .env.tmp deliberately NOT committed — it holds a live SNOWFLAKE_TOKEN and is not gitignored; left untracked in the working dir. Upstream deliberately unset on the DEV-1474 branch so a bare 'git push' cannot hit master. RESTORE: git checkout abhishek/dev-970/track-ai-billing-on-slack (its tip 825f0cff6 is unchanged and pushed); the parked tweak is on wip/repos-3-parked-20260724.

STILL OPEN: no DEV_ABHISHEK end-to-end ingestion run yet (would write dummy rows to sandbox bronze/silver — deleting the S3 file will NOT retract them). Cutover: decide when to stop the efp-derived/trades/northpond_ff -> purchase_tape/ mirror in sync_statements.py. Monitoring schedule intentionally omitted until Oliv confirms real-file cadence.
