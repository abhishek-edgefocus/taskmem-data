---
id: wm-n7usn7
type: task
title: DEV-1474: parse Oliv purchase files at finalised purchase_file/v0 path (v1 + _test ignored)
status: review
priority: p1
size: s
people: [Nate]
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-embhpy]
created: 2026-07-24T08:02:53Z
updated: 2026-07-24T16:29:25Z
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
- 2026-07-24T10:15Z [claude-code] 2026-07-24: PUSHED + PR RAISED. https://github.com/edgefocus/efp/pull/6011 (open, base master, head abhishek/dev-1474-ingest-northpond-purchase-tape-from-new-sftp-path, 2 files, +113/-0). Linear DEV-1474. Branch now tracks its own remote (upstream re-set by the push, no longer master). Awaiting review.

FOLLOW-UPS not in the PR: (1) stop the efp-derived/trades/northpond_ff -> statements/northpond/purchase_tape/ mirror in edgefocus/transformations/bronze/sync_statements.py once Oliv stops sending the Pool N xlsx; (2) add a MonitoringSchedule once Oliv confirms real-file cadence; (3) optional DEV_ABHISHEK end-to-end ingestion run — deferred because it writes dummy rows to sandbox bronze/silver and deleting the S3 object does NOT retract them (no delete reconciliation on the S3 statement path); (4) Oliv to remove the dummy file once testing is done.

REPO RESTORE (repos-3 still on the DEV-1474 branch): parked work is on wip/repos-3-parked-20260724 (6205bd0d9, the lib/efp/snowflake.py fetch_pandas_all fallback); original branch abhishek/dev-970/track-ai-billing-on-slack is unchanged at 825f0cff6. .env.tmp left untracked (live SNOWFLAKE_TOKEN, not gitignored).
- 2026-07-24T10:29Z [claude-code] 2026-07-24: END-TO-END RUN IN DEV_ABHISHEK — SUCCESS. Patch applied to repos-1 (~/repos/efp, the Dagster copy) as a working-tree overlay via git format-patch/git apply; applied cleanly, Abhishek's 12 in-flight uncommitted files untouched. NOT committed there — revert with: git checkout -- edgefocus/transformations/bronze/parsing_rules/northpond.py && rm edgefocus/transformations/bronze/northpond_patterns_test.py

SAFETY: confirmed get_database_name() resolves from the ENVIRONMENT env var (=dev) + USERNAME (=ABHISHEK) -> DEV_ABHISHEK. The ingest_statement_files --env flag ONLY selects the S3 scan prefix (prod -> s3://efp-raw/, dev -> s3://efp-sandbox/{USERNAME}/), it does NOT affect the Snowflake target. So --env prod reads real efp-raw and still writes to DEV_ABHISHEK. Note: these CLIs do NOT self-load .env; must 'set -a; . ./.env; set +a' first.

RESULTS: (1) ingest_statement_files backfill --platform northpond --env prod --filter purchase_file_legacy: dry-run 1 file WOULD insert; real run 1 inserted, status pending_statement_rows, no supersession. (2) ingest_statement_rows --platform northpond --statement-type purchase_tape --date 2026-07-23: 589 rows inserted into bronze.statement_rows (northpond/purchase_tape/2026-07-23/northpond_efhyf). (3) silver stmt_purchase_tapes --date 2026-07-23: MERGE LANDED — 589 rows / 589 distinct LOAN_ID in DEV_ABHISHEK.silver.northpond_stmt_purchase_tapes, alongside the 6 historical Pool events.

DATA QUALITY: BOOLEAN cast verified live — IS_HOME_OWNER/MODIFIED came from CSV strings '0'/'1' and materialised as a real mix (565 F/F, 23 T/F, 1 F/T), not collapsed to all-False. Typed cols parsed correctly (LOAN_AMOUNT float, VANTAGE_SCORE/CREDIT_GRADE int, INTEREST_RATE float, STATE varchar), LOAN_ID OLV-prefixed, FUND mapped to efhyf.

KNOWN NON-BLOCKING ISSUE: silver transform threw at the POST-merge step — DEV_ABHISHEK.SILVER.NORTHPOND_STMT_PURCHASE_TAPES_STREAM does not exist (stream on the TARGET table, consumed to propagate changes downstream). Sandbox provisioning gap, unrelated to DEV-1474; the merge itself completed. Would need the stream created in the sandbox to exercise downstream propagation.

FLAG FOR NATE (dummy-data artifact, but confirm for the REAL file): 59/589 rows have BLANK outstanding_principal_balance_as_of_funding_date and accrued_interest_as_of_funding_date in the source csv (1 blank employment_tenure). Verified these are genuinely empty cells in Oliv's file, faithfully carried to NULL — not a parsing defect. PROD comparison: all 372 real purchase-tape loans have 0 nulls in both columns. outstanding_principal feeds TAPE_PRINCIPAL/transfer amounts, so a blank on a REAL purchase would break transfers. Likely just dummy-generation noise given Nate said to ignore the values, but worth one line of confirmation.
- 2026-07-24T10:44Z [claude-code] 2026-07-24: PURCHASE TAPE TABLE COMPARED THOROUGHLY (new 589 csv rows vs existing 372 xlsx rows, DEV_ABHISHEK.silver.northpond_stmt_purchase_tapes). Downstream deliberately not tested per Abhishek.

STREAM QUESTION SETTLED: NORTHPOND_STMT_PURCHASE_TAPES_STREAM DOES exist in PROD.SILVER (verified via SHOW STREAMS — all 10 platform purchase-tape streams present there). So the dev failure is purely a sandbox provisioning gap; prod is unaffected. Abhishek was right.

STRUCTURE — IDENTICAL: LOAN_ID 589/589 OLV-prefixed, single distinct length; STATE 2-char 589/589; APPLICATION_UUID 36-char 589/589; FUND single value efhyf; 589 rows / 589 distinct LOAN_ID, ZERO dupes. Null rates identical to the xlsx rows on 19 of 22 columns.

*** ONE REAL FORMAT DISCREPANCY (investigated, benign) ***: PURCHASE_DATE and FUNDING_DATE are VARCHAR. OLD xlsx rows are LENGTH 19 ('2025-02-05 00:00:00' — pandas read_excel produced datetimes). NEW csv rows are LENGTH 10 ('2026-07-23' — S3CsvFile reads dtype=str so the raw string is preserved). So the two vintages are NOT byte-identical in those columns. VERIFIED NOT A PROBLEM: northpond consumes these via TRY_TO_DATE(PURCHASE_DATE) (see northpond constants + positions.py), and TRY_TO_DATE parses BOTH formats to the same DATE — tested live, 0 unparseable rows in either vintage. RESIDUAL RISK: any NEW downstream code doing raw string comparison / LIKE / SUBSTR on these VARCHARs would see different formats. Worth knowing, not worth blocking.

NULL DIFFS (dummy artifact, already flagged): ACCRUED_INTEREST and OUTSTANDING_PRINCIPAL 10.0% null on new (59/589) vs 0.0% on old; EMPLOYMENT_TENURE 0.2% (1/589) vs 0.0%.

VALUE RANGES — clearly dummy, NOT purchase-tape-like (reinforces that these are seasoned loans, not fresh purchases): DPD new max 553 / avg 74.3 vs old max 2 / avg 0.01; ORIGINAL_TERM new min 4 vs old always 36; REMAINING_TERM new 12-28 vs old 29-36; INTEREST_RATE new min 0.0 vs old min 12.58; OUTSTANDING_PRINCIPAL new min 0.0 vs old min 836.37; PRISM_CASH_SCORE new min 0.0 vs old min 84; BORROWER_INCOME_ANNUAL new max 5,971,680 vs old max 756,000. Nate said to ignore the values, so this is expected — but it means the file tells us nothing about real-file value sanity.

VERDICT: structurally the new rows match the existing rows; the only structural difference is the VARCHAR date format, which is benign under TRY_TO_DATE. Value-level differences are all dummy-generation noise.
- 2026-07-24T10:53Z [claude-code] 2026-07-24: REMAINING NON-LOCAL ISSUES (Abhishek asked to exclude local-env/dev-sandbox/dummy-data noise).

*** BIGGEST: the purchase tape table DRIVES FUND CLASSIFICATION. *** constants.py:40 FUND_WITH_PURCHASE_TAPE_EXPR does: IFF(LoanNumber IN (SELECT LOAN_ID FROM silver.northpond_stmt_purchase_tapes WHERE TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE), 'efhyf', <standard account->fund mapping>). It is consumed by stmt_positions.py AND stmt_transactions.py. So EVERY loan added to the purchase tape is thereby classified into EFHYF for positions and transactions. Widening the purchase tape silently widens EFHYF. This is the concrete production consequence of the earlier grain question: if the legacy file is ever broader than genuine EFHYF purchases (the dummy carried 589 loans of which 255 were NOT in the existing prod purchase tape), those loans get reassigned to efhyf in silver.positions/transactions. Safe ONLY if the file really is incremental genuine purchases, as Abhishek states Nate confirmed. Worth an explicit reconciliation the first time a REAL file lands: compare new LOAN_IDs against expected purchases before/after the silver run.

OTHER CONSUMERS of silver.northpond_stmt_purchase_tapes (blast radius): transfers.py, gold/northpond_tu_offers_daily.py, gold/northpond_tu_offers_bucketed.py, orchestration/assets/northpond_assets.py, orchestration/jobs/statements_northpond.py.

AS_OF_DATE INVARIANT CHANGE: for all 6 historical Pool files AS_OF_DATE == PURCHASE_DATE exactly (verified in prod). The new rule derives AS_OF_DATE from the FILENAME (file-generation date) while PURCHASE_DATE comes from file content. Same-day generation keeps the invariant; next-day generation breaks it. Matters because FUND_WITH_PURCHASE_TAPE_EXPR filters TRY_TO_DATE(PURCHASE_DATE) <= AS_OF_DATE — a file generated BEFORE its own purchase_date would drop those loans from the efhyf classification. Confirm with Oliv that the file is generated on/after the purchase date.

SUPERSESSION IS NARROWER THAN IT LOOKS: priority=1 only bites when the csv and xlsx share (platform, statement_type, as_of_date, account_name). xlsx as_of_date = purchase-agreement date; csv as_of_date = file-generation date. If both feeds run with differing dates for one purchase, it double counts. Real mitigation is a clean cutover, not the priority flag.

NO MonitoringSchedule: if Oliv goes daily and a file is missed, nothing alerts.

PR 6011 CI: Run Tests pass (11m7s), Select tests pass, Cursor Bugbot pass, Seer Code Review pass, integration tests skipped. MERGEABLE, blocked only on REVIEW_REQUIRED.
- 2026-07-24T10:58Z [claude-code] 2026-07-24: ISSUE LIST CLOSED OUT by Abhishek. Explicitly waived / not applicable: (a) AS_OF_DATE-from-filename vs PURCHASE_DATE ordering — fine; (b) multiple programs / Nate's future folder changes — not expected, ignore; (c) purchase tape -> EFHYF classification — INTENDED, everything in the purchase tape is the high-yield fund by design; (d) csv-vs-xlsx cutover double count — only CSVs expected going forward, no parallel xlsx feed; (e) MonitoringSchedule absence — fine; (f) all local-env / repos-1 overlay / .env.tmp / DEV_ABHISHEK sandbox state / dummy-data value noise — Abhishek will repopulate dev from prod.

MY POINT ABOUT THE STANDARD FILE WAS MIS-FRAMED and is withdrawn: it was a forward-looking note about a migration NOT being made. We ingest ONLY purchase_file_legacy/. The standardised purchase_file/ folder matches NO rule and test_new_standard_purchase_file_not_ingested locks that in. The legacy csv carries application_uuid fully populated (589/589, 36-char), so gold/northpond_tu_offers_daily.py and _bucketed.py (which join the purchase tape on application_uuid) are unaffected.

NET: no material open issues on DEV-1474 as scoped. Substantive checks that passed on their own merits: exact 21-col match, 0 missing/extra, 0 dupes, 589 distinct loans; BOOLEAN casts verified live with a real T/F mix; the single structural difference (PURCHASE_DATE/FUNDING_DATE VARCHAR 19-char xlsx vs 10-char csv) traced to BOTH consumers — FUND_WITH_PURCHASE_TAPE_EXPR and transfers.py:140 — and confirmed benign because both wrap it in TRY_TO_DATE, 0 unparseable rows either vintage. PR 6011 CI fully green; MERGEABLE, blocked only on REVIEW_REQUIRED.

REMAINING ACTION: get a reviewer on PR 6011. Then merge + cutover.
- 2026-07-24T11:02Z [claude-code] 2026-07-24: RAN VIA DAGSTER (dexterplus) — the runner gap is now closed. Per-user Dagster stacks on dexterplus.edgefocus.net; Abhishek's is dagster-webserver-abhishek on host port 13053 (container 3000), postgres 15053. Container bind-mounts ~/repos/efp/edgefocus -> /app/edgefocus:ro, so the repos-1 working-tree overlay is LIVE inside the container — verified the container itself resolves northpond_purchase_tape_legacy_csv with priority 1.

COMMAND THAT WORKS (note: 'bash -lc' wipes PATH, and 'asset materialize' has NO -w flag; must use -f/-d):
docker exec -w /app/orchestration dagster-webserver-abhishek /app/.venv/bin/dagster asset materialize -f /app/orchestration/definitions.py -d /app/orchestration --select northpond_stmt_purchase_tapes

RUN 467ce559-a728-442b-b715-73b2442634e1 (recorded in the instance, visible in UI). Transform itself SUCCEEDED end to end through Dagster: watermark ensured for BRONZE.STATEMENT_ROWS -> SILVER.NORTHPOND_STMT_PURCHASE_TAPES, found 1 key ['2026-07-23'], temp table 589 rows, deleted 589, inserted 589. Run then FAILED at the final step 'Consuming NORTHPOND_STMT_PURCHASE_TAPES stream' — the SAME missing-sandbox-stream gap as the CLI run, which Abhishek has waived (stream exists in PROD.SILVER, verified).

BONUS — IDEMPOTENCY NOW PROVEN (was previously on my untested list): the Dagster run re-processed the same file and did DELETE 589 -> INSERT 589, i.e. replace-not-append. Re-delivery of the same file does NOT duplicate rows.

DAG UNCHANGED as Abhishek expected: no Dagster asset was added or modified: the change is a bronze parsing rule only, so the asset graph is byte-identical. northpond_stmt_purchase_tapes is part of job statements_northpond (orchestration/jobs/statements_northpond.py).

URLs: run http://dexterplus.edgefocus.net:13053/runs/467ce559-a728-442b-b715-73b2442634e1 ; asset http://dexterplus.edgefocus.net:13053/assets/northpond_stmt_purchase_tapes ; webserver returns HTTP 200.
- 2026-07-24T11:11Z [claude-code] 2026-07-24: DAGSTER RUN NOW GREEN — root cause of the earlier failure found, and it was NOT 'sandbox never provisioned' (my earlier framing was WRONG; Abhishek correctly said these runs had succeeded before).

ROOT CAUSE: DEV_ABHISHEK.SILVER was DB-RESET on 2026-07-23 07:27 (all silver tables show CREATED 2026-07-23 07:27). A Snowflake db-reset/table-replace DROPS dependent streams. Only 3 streams were hand-recreated afterwards at 2026-07-23 07:39 — NORTHPOND_STMT_ISSUANCE_STREAM, NORTHPOND_STMT_ISSUANCE_V2_STREAM, PREDICTIONS_STREAM — i.e. exactly the DEV-1468 work in flight at the time. Dev silver had 3 streams vs 107 tables. EVIDENCE it worked before: dagster event_logs for asset northpond_stmt_purchase_tapes show 16 ASSET_MATERIALIZATION (success) events with the last on 2026-06-23 — i.e. BEFORE the reset — vs 20 ASSET_MATERIALIZATION_PLANNED. Terraform is the source of truth (terraform/snowflake/silver_northpond_stmt_purchase_tapes.tf:192 declares NORTHPOND_STMT_PURCHASE_TAPES_STREAM with replace_triggered_by the table) and is not applied to dev sandboxes. Abhishek's own slop/create_missing_streams.py docstring confirms the mechanism: 'Create missing Snowflake streams that were dropped during db-reset'.

FIX APPLIED (dev only): created DEV_ABHISHEK.SILVER.NORTHPOND_STMT_PURCHASE_TAPES_STREAM ON TABLE ... APPEND_ONLY = FALSE, matching the terraform definition. Reports stale=false.

RE-RUN ee248d14-7f34-4e2b-894d-b260e559912b = RUN_SUCCESS (verified via GraphQL). Full clean path: found 1 key ['2026-07-23'] -> temp table 589 rows -> deleted 589 -> inserted 589 -> stream consumed successfully -> watermark updated -> 'transformation completed: 589 deleted, 589 inserted'. Idempotency re-confirmed a second time (delete-then-insert, no duplication).

NOTE FOR ABHISHEK: slop/create_missing_streams.py only covers 4 streams (TRANSACTIONS, TRANSACTIONS_ITD, TRANSFERS, POSITIONS). The sandbox is still missing ~100 other streams from the same reset, so other assets will fail identically until that script is extended or terraform is applied to dev.

URLs: green run http://dexterplus.edgefocus.net:13053/runs/ee248d14-7f34-4e2b-894d-b260e559912b ; earlier failed run 467ce559-a728-442b-b715-73b2442634e1.
- 2026-07-24T12:37Z [claude-code] 2026-07-24: DUMMY FILE DELETED FROM S3. Removed s3://efp-raw/statements/northpond/purchase_file_legacy/2026/07/purchase_file_legacy_20260723.csv (107,134 bytes, the only object under that prefix). Prefix now empty.

RECOVERABLE: efp-raw has versioning ENABLED, so this was a soft delete. Delete marker VersionId iYQbSyHRy_2HvboCiI8GokzpvD.R471. ; original object still present as VersionId Yo1kccU0wu1reJagbaqpY3CiFP87.68u (107,134 bytes). Restore = delete the delete-marker version.

NO EFS COPY to clean: /efs/data/statements/northpond/ is not reachable from dexterplus (host has no such path; the container mounts /efs read-only and the northpond path does not exist there). The SFTP->EFS->S3 sync runs in the prod environment, not on dexterplus.

*** WILL COME BACK: the file is still on Oliv's SFTP. *** Nobody has asked Nate to remove it yet — that was always the plan AFTER dev testing. Since edgefocus/sftp/northpond.py mirrors Oliv's whole remote tree into statements/northpond/ (exclude-list only, no allowlist), the next prod sync run will re-copy the file straight back into S3. Deleting from S3 is therefore only durable once Oliv removes it from their SFTP. ACTION: ask Nate to delete purchase_file_legacy/2026/07/purchase_file_legacy_20260723.csv from the SFTP. Optionally, if it needs to stay on their side, add it to the _EXCLUDE list in edgefocus/sftp/northpond.py.

ALSO NOT RETRACTED by the S3 delete (as established earlier — no delete reconciliation on the S3 statement path): the 589 rows already in DEV_ABHISHEK bronze.statement_files / bronze.statement_rows / silver.northpond_stmt_purchase_tapes. Abhishek has said he will repopulate dev from prod, so leaving them.
- 2026-07-24T12:38Z [claude-code] 2026-07-24: PROD CHECKED — NO DATA CONTAMINATION, but one orphan row + a REAL SEQUENCING RISK.

PROD IS CLEAN: bronze.statement_rows has ZERO northpond/purchase_tape rows for anything in 2026. PROD.silver.northpond_stmt_purchase_tapes is UNCHANGED — still exactly 372 rows / 372 loans across the same 6 Pool events (2025-02-05, 03-20, 04-22, 05-09, 05-23, 06-17). Nothing from the dummy landed in prod.

ONE ORPHAN ROW: PROD.bronze.statement_files contains s3://efp-raw/statements/northpond/purchase_file_legacy/2026/07/purchase_file_legacy_20260723.csv with STATUS='unknown' and PLATFORM/STATEMENT_TYPE/AS_OF_DATE/RULE_NAME all NULL. Expected and harmless: prod's SQS-driven file registration saw the new S3 object, found no matching parsing rule (DEV-1474 is not merged), and filed it as 'unknown' = 'No matching rule found' (ingest_statement_files.py:17). No rows were parsed from it.

*** SEQUENCING RISK — merge order matters. *** ingest_statement_files has a 'refresh' subcommand explicitly documented for exactly this case: 'New parsing rules are added and you want to categorize previously unknown files' (line 1033), usage example at line 1147 is literally . So once DEV-1474 merges, that orphan row is re-evaluated against the new rule. Combined with the fact that the file WILL be re-synced from Oliv's SFTP (they have not been asked to remove it yet), merging before Oliv deletes it means PROD ingests 589 DUMMY rows into silver.northpond_stmt_purchase_tapes — and because FUND_WITH_PURCHASE_TAPE_EXPR classifies everything in the purchase tape as EFHYF, those 589 loans would be pulled into efhyf in silver.positions and silver.transactions.

REQUIRED ORDER: (1) Nate deletes the dummy from Oliv's SFTP; (2) confirm it no longer re-appears in s3://efp-raw/statements/northpond/purchase_file_legacy/; (3) THEN merge PR 6011. If the merge must happen first, either add the file to _EXCLUDE in edgefocus/sftp/northpond.py or make sure nobody runs  for northpond until the file is gone.
- 2026-07-24T12:39Z [claude-code] Correction to previous entry: backticks were shell-substituted, so one line lost its content. The refresh usage example at ingest_statement_files.py:1147 reads: refresh --status unknown --filter northpond
- 2026-07-24T12:44Z [claude-code] 2026-07-24: CANNOT verify Oliv SFTP directly from dexterplus. edgefocus/sftp/northpond.py resolves creds via require_secret(NORTHPOND_SFTP_HOST/USER/PASSWORD), and the dexterplus IAM user (arn:aws:iam::508533208338:user/dexter-plus-ubuntu) gets AccessDeniedException on secretsmanager:GetSecretValue for northpond_sftp_*. Password is not in any local .env either; .env.example:72-74 only documents host=sftp-public-prod.olivfinancial.com user=edgefocus with the password redacted. So a direct SFTP listing is not possible from this host — would need creds or to run from an environment with Secrets Manager access.

INDIRECT CHECK SET UP INSTEAD (and it tests the thing that actually matters): the prod sync mirrors Oliv SFTP -> EFS -> S3 with an exclude-list only, so if the file were still on their SFTP it would be re-copied into s3://efp-raw/statements/northpond/purchase_file_legacy/. I deleted the S3 object at ~12:37Z. Monitoring that prefix for 60 min (12 checks, 5 min apart). Prefix staying empty = Nate genuinely removed it and the merge gate is clear; reappearance = still present on their side and PR 6011 must NOT be merged yet.

Nate told Abhishek on 2026-07-24 that he has deleted the file from Oliv SFTP.
- 2026-07-24T12:57Z [claude-code] 2026-07-24 IMPORTANT: OLIV CHANGED THE FILE PATHS AFTER PR 6011 MERGED. The merged rule is now a NO-OP.

NATE 2026-07-24 18:09 IST (ts 1784896779.651619): "I have deleted the file. We have slightly modified/finalized the specs for the purchase file delivery." NEW PATHS (v0 = legacy, v1 = new):
  /purchase_file/v0/{YYYY}/{MM}/purchase_file_v0_{date}.csv
  /purchase_file/v1/{YYYY}/{MM}/purchase_file_v1_{date}.csv
Abhishek confirmed the trailing slash after v1; Nate reacted with a checkmark. Abhishek replied "I will add these in our configs."

IMPACT ON MERGED CODE (commit 1bda6b22, merged 11:46:47Z, NOT yet deployed to prod):
1. The merged rule pattern is .../statements/northpond/purchase_file_legacy/\d{4}/\d{1,2}/purchase_file_legacy_(?P<date>\d{8}).*\.csv — it will now match NOTHING. purchase_file_legacy/ is abandoned and its S3 prefix is empty.
2. The negative test test_new_standard_purchase_file_not_ingested asserts purchase_file/2026/07/purchase_file_20260723.csv matches no rule. Under the new scheme purchase_file/v0/... is exactly what we DO want to ingest, so that test now encodes a stale assumption — it still passes but is misleading.
3. *** TRAP: _test FILES. *** Nate will regularly drop e.g. purchase_file_v0_20260724_test.csv ("these are not real and we can wipe them out"). The merged pattern uses (?P<date>\d{8}).*\.csv — the trailing .* happily matches _test. A naive port of that pattern to the new path WOULD INGEST NATE-S STUB TEST FILES INTO PROD. The new rule must exclude _test (or add an explicit ignore rule for it).

FOLLOW-UP PR NEEDED: (a) new rule for purchase_file/v0/YYYY/MM/purchase_file_v0_YYYYMMDD.csv; (b) exclude _test; (c) leave purchase_file/v1/ unmatched with a test asserting that; (d) remove the now-dead purchase_file_legacy rule; (e) replace the stale negative test.

*** GRAIN QUESTION DEFINITIVELY CLOSED BY NATE *** 2026-07-23 23:56 IST, two messages I had not seen earlier: "I think we will need to nail down the exact file cadence/delivery but my current expectation is that we will produce a daily purchase file (both legacy and the new version) and upload to sftp each day" AND "A given loan should appear on only one file ever". That is direct confirmation of the incremental / no-duplicates semantics Abhishek asserted — my earlier concern is resolved from the source. It also means the cadence IS daily, so the omitted MonitoringSchedule is now worth adding.

CURRENT STATE 12:56Z: new purchase_file/ prefix NOT yet in S3 despite Nate saying at 18:24 IST "Purchase files uploaded anyway to the proposed file paths". purchase_file_legacy/ empty. issuance_v2/ has only the 2026-07-23 file (Abhishek still awaiting a fresh one to validate). PROD still clean: 372 rows, no 2026 purchase_tape rows. Prod deploy is MANUAL workflow_dispatch with required reviewers; last deploy 2026-07-23 20:53Z on 44a6884e, so the merge is not live.
- 2026-07-24T15:45Z [claude-code] 2026-07-24: FOLLOW-UP PR RAISED — https://github.com/edgefocus/efp/pull/6013 (branch abhishek/dev-1474-parse-new-purchase-file-paths, commit e65592dba, base master 75b843584). Same ticket DEV-1474, follows PR 6011.

WHY: Oliv finalised the spec AFTER 6011 merged, so the merged rule matches nothing. New paths purchase_file/v0/... (legacy schema, ingest) and purchase_file/v1/... (new schema, ignore).

WHAT: (1) new rule northpond_purchase_tape_v0_csv, pattern .../purchase_file/v0/YYYY/MM/purchase_file_v0_(?P<date>8digits)(_N)?.csv, %Y%m%d, S3CsvFile, statement_type=purchase_tape, account_name=northpond_efhyf, priority=1; (2) ignore rule for any purchase_file/**/*_test.csv; (3) ignore rule for purchase_file/v1/**; (4) removed the dead purchase_file_legacy rule; (5) rewrote northpond_patterns_test.py (9 tests).

_TEST GUARDED TWICE (deliberate): find_matching_rule returns the FIRST match so both ignore rules are ordered ahead of the ingest rule; AND the ingest pattern allows only a numeric dedup suffix after the date, so _test cannot match it even without the ignore rule. A loose .*\.csv here would silently pull Oliv stub data into prod — that was the trap in the 6011 pattern.

SCHEMA VERIFIED against Nates actual samples: v0 = 21 cols, ZERO missing, ZERO extra, SAME ORDER as the silver source columns. v1 = 17 cols (oliv_loan_number, accrued_interest_on_purchase_date, principal_on_purchase_date, annual_interest, homeowner, vantage_score_v4, post_dti, days_past_due, plus a column literally named "coalesce") — confirms v1 must stay out of purchase_tape.

TESTS: 9 new tests pass; 553 passed across edgefocus/transformations/bronze/ + orchestration/tests/bronze_statement_file_arrival_test.py; ruff + mypy clean. Routing table verified for all 8 real-world path shapes incl. both _test variants.

STILL OPEN: nothing has appeared under s3://efp-raw/statements/northpond/purchase_file/ as of 13:0xZ despite Nate saying at 18:24 IST the files were uploaded — worth confirming the upload location with him. Also note Nates path example contained a typo, 2026}/07/, worth confirming it is not in their generator.
- 2026-07-24T16:29Z [claude-code] 2026-07-24: PR 6013 VERIFIED END-TO-END ON DEXTERPLUS — the _test question for Nate is ANSWERED: YES, safe for Oliv to keep dropping test files.

NATE ALREADY DELIVERED to the new paths (arrived in efp-raw 2026-07-24 13:37:14): purchase_file/v0/2026/07/purchase_file_v0_20260723_test.csv (1033 B) and purchase_file/v1/2026/07/purchase_file_v1_20260723_test.csv (731 B). Both are _test stubs.

TEST 1 — REAL files, prod prefix scan (repos-3 on the PR branch, ENVIRONMENT=dev so writes go to DEV_ABHISHEK): both of Nate real stub files registered as STATUS=ignore, statement_type NULL, rule_name NULL. ingest_statement_rows --statement-type purchase_tape then reported "No files with data to process", 0 files / 0 rows. Nothing leaked.

TEST 2 — full routing matrix staged in s3://efp-sandbox/abhishek/statements/northpond/purchase_file/ and scanned with --env dev. Result, 6 purchase_file entries, exactly ONE ingestable:
  v0/purchase_file_v0_20260723_test.csv  -> ignore
  v0/purchase_file_v0_20260724.csv       -> pending_statement_rows, purchase_tape, 2026-07-24, rule northpond_purchase_tape_v0_csv
  v0/purchase_file_v0_20260724_test.csv  -> ignore
  v1/purchase_file_v1_20260723_test.csv  -> ignore
  v1/purchase_file_v1_20260724.csv       -> ignore
  v1/purchase_file_v1_20260724_test.csv  -> ignore
  purchase_file_legacy/...               -> unknown (rule removed, as intended)
  Pool 1-6 xlsx                          -> rows_added, unchanged
POSITIVE CONTROL PASSED: the non-test v0 ingested 4 rows to bronze, then Dagster asset northpond_stmt_purchase_tapes run bb0ab333-c5fb-4fe2-9195-de36e8a953fe = RUN_SUCCESS ("0 deleted, 4 inserted"), stream consumed successfully, watermark updated.

SILVER RESULT: as_of_date 2026-07-24 = 4 rows / 4 loans, account northpond_efhyf, fund efhyf. Values correct and typed (OLV12563419-22, amounts 1000/2500/1000/4000, vantage 595/596/601/562, rates 22.06/22.02/22.06/26.77, states MO/FL/FL/MI, IS_HOME_OWNER False, all 4 application_uuids populated).
V1 CONTAMINATION CHECK: 0 rows missing APPLICATION_UUID at 2026-07-24. Since v1 has no application_uuid column, any v1 leak would have shown as NULLs there. Clean.

CLEANUP: sandbox fixtures removed from s3://efp-sandbox/abhishek/statements/northpond/purchase_file/. repos-1 NOT touched this round (it is on branch abhishek/dev-1468-ingest-oliv-issuance-v2-anl with its own +37 lines in northpond.py and predates the 6011 merge) — the bronze runs were driven from repos-3 which holds the exact PR code, and the Dagster silver asset does not depend on the parsing rules.
