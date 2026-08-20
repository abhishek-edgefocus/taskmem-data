---
id: wm-prm54n
type: task
title: Deprecate OpenRoad datastores by 2026-08-03 (milestone at 0%)
status: next
priority: p1
size: l
due: 2026-08-03
people: [Abhijeet]
tags: [openroad, datastores]
links: [relates:wm-bvqkhh, relates:wm-tvjjgw, blocks:wm-skvqac, parent:wm-jr5bup]
refs: [DEV-1486=https://linear.app/edge-focus/issue/DEV-1486/deprecate-openroad-datastores]
created: 2026-07-29T15:33:30Z
updated: 2026-08-20T11:52:26Z
source: claude-code
label: OpenRoad datastore deprecation
---

Abhijeet asked directly in DM 2026-07-29 19:50 IST (D0B2A3WSJ5N): "openroad deprecate
datastores on track to be done by 3rd aug?" — so he is actively tracking this to a date.

CONFIRMED IN LINEAR 2026-07-29: OpenRoad Data Ingestion project milestones —
- Validate positions   — 100%, target 2026-07-08 (hit)
- Validate predictions —  25%, target 2026-07-31  (= DEV-1331, its only issue, now In
                                                    Review; [[wm-bvqkhh]])
- **Deprecate datastores — 0%, target 2026-08-03**  <- this item
Project lead is Abhijeet. The deprecation milestone has not started.

WHAT ABHISHEK TOLD HIM (same exchange):
- The openroad predictions PR is up and review-requested from Abhijeet ("baghto").
- Abhijeet: "tech urlay na phakta?" (is that the only thing left?) — Abhishek: "Ekda check
  karava lagel I think mostly ho" (need to check once, I think mostly yes). **That check is
  an open action and is the first step here** — the answer given was hedged, and the
  milestone reads 0%, which does not match "mostly only that left".
- Abhijeet then asked whether BEP was added — it is not; CMOP and BEP are outstanding for
  BOTH platforms (OpenRoad and NorthPond). Tracked separately.

SEQUENCING: predictions validation (2026-07-31) gates this (2026-08-03) — three days apart,
and the predictions PR still needs Abhijeet's approval, then prod re-materialisation and a
notebook re-run before DEV-1331 can close. That is a tight chain; if the PR sits, 08-03
slips.

Adjacent risk on the NorthPond side, same theme: [[wm-tvjjgw]] (legacy northpond datastore
silently starving as Oliv moves files).

## Log
- 2026-07-29T16:44Z [claude-code] READINESS AUDIT 2026-07-29 (Linear + master code + PROD Snowflake + S3). The 08-03 milestone is not reachable as scoped; the registry PR is the small part, the data is the blocker.

1. LINEAR: 'Deprecate datastores' milestone (b4cc3095, target 2026-08-03) contains ZERO issues — 0% is 'nothing tracked', not 'not started'. Project target 2026-08-04, lead Abhijeet. Northpond's equivalent was DEV-1450. A ticket has to be created before anything else.

2. PRIMARY BLOCKER — Snowflake does not hold OpenRoad history. S3 s3://efp-raw/statements/openroad/ has 1,101 LoanTape_Edge_Orl files (2023-07-24..2026-07-28), 1,080 Payments_Edge_Orl (2023-08-14..2026-07-28), 29 Transactions_Edge_Orl (2023-07-25..2024-12-18), 33 funding tapes. PROD bronze.statement_rows openroad: positions 1,050 rows/30 dates (2026-06-29..07-28), payments 26 rows/15 dates, purchase_tape 38 rows/33 dates. PROD silver: openroad_stmt_positions 280 rows/8 dates; openroad_stmt_payments 7 rows/4 dates; openroad_stmt_transactions 0 ROWS (empty); openroad_stmt_purchase_tapes 35 rows/31 dates (only healthy one). silver.positions openroad = 280 rows/35 loans/8 dates; silver.transactions openroad = 7 ROWS/6 loans. So source='snowflake' routing would serve 8 of 1,101 days of positions and 7 transaction rows. ~1,070 loan-tape days + ~1,065 payment days + 29 transaction days need bronze ingest then the full silver chain, IN PROD. The pipeline itself is fully wired (orchestration/jobs/statements_openroad.py, 9 assets) — this is a data backfill, not code.

3. PARITY/QUALITY GAPS that a comparison would fail on today:
- silver.positions openroad CREDIT_SCORE + CREDIT_SCORE_AT_PURCHASE 280/280 NULL. Legacy reads vantage4Score via StatementGatewayGetOffers/StatementResponses; that is DEV-1396, still Todo and NOT attached to the project or any milestone. silver.openroad_offers VANTAGE4 = 3,021 non-null of 5,821,315.
- FIRST_PAYMENT_DUE_DATE 280/280 NULL -> MOB = accrual+1; PR #5974's MOB alignment is unverifiable until the history backfill restores early snapshots ([[wm-bvqkhh]] 12:37Z entry).
- silver.transfers openroad: 35 rows, EFP_ID NULL on all 35, FROM_FUND NULL on all 35.
- silver.predictions openroad still APP_ID-keyed (openroad_4675720..5392528), last generation_ts 2026-07-07 13:00 — prod never re-materialized after DEV-1393; joins 0/35 to silver.positions.
- silver.predicted_cashflows openroad: FEES 0/2507, NET_CASH_FLOW 0/2507, RECOVERY 140/2507, loaded_at 2026-07-07 — the NaN-config corruption; PR #5974 fixes it but only post-merge + prod rebuild.
- silver.positions openroad is single account/fund ('Edge - ORL' / efhyf) — no fund movement, unlike northpond.

4. THE DEPRECATION PR ITSELF — NOT STARTED. openroad has ZERO hits in datastore_deprecations.py (sofi/prosper/marlette/happymoney/upgrade/northpond all registered). Needs 2 entries: ('DatastorePositions','openroad') -> silver.positions and ('DatastoreTransactions','openroad') -> silver.transactions, plus the same two judgement calls northpond had (positions_snowflake_map.PLATFORM_RENAMES; HISTORY_DERIVED_PLATFORMS; transactions_snowflake_map.PLATFORM_NULL_COLUMNS). Early read: legacy openroad has no fund/account adjustment at all (DatastoreStandardizedPositionsOpenroad sets channel='openroad_auto_refi', purchase_date='Funded Date' from StatementFunding deduped to one row per loan) => origination/funding-anchored like northpond, NOT history-derived — but confirm with a column diff. Note openroad's classes are DatastoreStandardizedPositionsOpenroad / DatastoreTransactionsOpenroad(BaseDatastoreTransactionsFoursight); maybe_warn_deprecated keys on self.__class__.__name__, so verify the registry key actually fires for the openroad call path (northpond used the base names). No code outside lib/efp/stats/datastores/openroad/ imports the legacy classes — only two docstring/comment mentions in silver openroad transactions.py and orchestration/assets/openroad_assets.py.

5. TRANSACTIONS PARITY HAS NEVER BEEN RUN for openroad. Milestones cover positions (DEV-1350, Done) and predictions (DEV-1331, In Review); northpond had DEV-1275 + DEV-1332 covering BOTH before registering. With silver.transactions at 7 rows there is nothing to compare yet anyway.

6. GATING CHAIN unchanged: DEV-1331 / PR #5974 needs Abhijeet's approval -> merge -> prod rebuild in the mandatory order (openroad_offers FIRST, then a forced full predictions reprocess) -> notebook re-run -> close. Then the backfill, then parity, then the registry PR. CMOP/BEP scope for 08-03 still unresolved ([[wm-xe6w4q]]).
- 2026-07-29T16:49Z [claude-code] CRITICAL PATH ESTABLISHED 2026-07-29 (user asked for an ordered plan to hit 08-03).

KEY SCOPE FINDING: the deprecation registry only ever covers DatastorePositions + DatastoreTransactions — 12 entries = 6 platforms x 2, NO platform registers a predictions datastore. So DEV-1331 / PR #5974 (predictions) is NOT on the deprecation critical path; it gates the separate 07-31 'Validate predictions' milestone only. The backfill + parity + registry work can proceed in parallel with waiting on Abhijeet's review.

BACKFILL IS SMALLER THAN IT SOUNDS: PROD bronze.statement_files has only 93 openroad files registered vs 2,247 in S3 (payments 15 rows_added + 15 rows_added_empty, positions 30, purchase_tape 33; ZERO 'transactions' statement_type files ever registered). Files are tiny — LoanTape 1.3KB (2023) to 16.6KB (2026), 35 loans total, so the whole 3-yr backfill is ~15MB across ~2,150 files. File-count-bound, hours not days => 08-03 is realistic if the backfill starts now.

ORDERED PLAN:
1. Create the Linear ticket in milestone b4cc3095 (mirrors DEV-1450) — milestone currently has zero issues, which is why Abhijeet sees 0%.
2. Backfill the file registry: python -m edgefocus.transformations.bronze.ingest_statement_files backfill --platform openroad --env prod (supports --dry-run, --filter, --limit). Verify statement_files openroad 93 -> ~2,200 pending_statement_rows, incl. the 29 Transactions_Edge_Orl files.
3. Let bronze parse: the ingest_statement_files Dagster job (schedule */30, max_runtime 2h, MULTIPROCESS_EXECUTOR) selects assets copy_from_efs, clean_pii_statements, sync_statement_files, statement_files, statement_rows — so pending files drain automatically. Verify bronze.statement_rows openroad positions min as_of_date moves 2026-06-29 -> 2023-07-24.
4. Rebuild silver in prod via the statements_openroad job (9 assets, full history). Expect silver.positions openroad 280 rows/8 dates -> ~32K rows/~1,080 dates (matches what dev held on 2026-07-17), silver.transactions 7 rows -> real volume, openroad_stmt_transactions 0 -> populated, and FIRST_PAYMENT_DUE_DATE to stop being 100% NULL (the back-calc needs early snapshots).
5. Parity-check positions AND transactions vs get_datastore_data(DatastorePositions/DatastoreTransactions, platforms=['openroad']). Transactions parity has never been run for openroad at all.
6. Settle the 3 map settings from step 5's column diff: positions_snowflake_map.PLATFORM_RENAMES; HISTORY_DERIVED_PLATFORMS (early read: OUT, funding-anchored like northpond); transactions_snowflake_map.PLATFORM_NULL_COLUMNS (early read: nothing to null — openroad is single account 'Edge - ORL' / single fund efhyf, no fund movement, unlike northpond).
7. Ship the registry PR: 2 DEPRECATION_REGISTRY entries + step 6's settings. ~3 files / ~50 lines, mirrors DEV-1450.

SCOPE RISK TO SETTLE EARLY WITH ABHIJEET: step 5 will surface CREDIT_SCORE + CREDIT_SCORE_AT_PURCHASE as a hard parity failure (legacy populates from vantage4Score, silver is 280/280 NULL). Either document it as a known gap northpond-style and ship, or block on DEV-1396 — that decision is the only thing likely to push past 08-03. Ask before step 5, not after.
- 2026-07-31T12:56Z [claude-code] Linear ticket now exists: DEV-1486 'Deprecate OpenRoad Datastores' (Development, Todo, labels OpenRoad + Datastores), created 2026-07-29 16:16Z — i.e. right after Abhijeet's 'on track for 3rd aug?' DM. Ref added. Still unstarted as of 2026-07-31, with the milestone target two days away (2026-08-03), and its upstream gate PR #5974 is approved but unmerged.
- 2026-07-31T22:03Z [claude-code] 2026-08-01: DRAFT PR #6133 raised — https://github.com/edgefocus/efp/pull/6133 (branch abhishek/dev-1486-deprecate-openroad-datastores off master, commit 46f103101, 2 files +32/-0). This is step 7 of the ordered plan; steps 2-6 (backfill -> silver rebuild -> parity) are still NOT done, so it is deliberately a draft and the PR body carries a 'Do not merge yet' section.

WHAT SHIPPED: datastore_deprecations.py 2 entries (DatastorePositions/DatastoreTransactions, openroad, snowflake_routable=True, deprecate_after 2026-08-03); positions_snowflake_map.py openroad entry with 3 renames. transactions_snowflake_map.py NEEDS NO CHANGE.

THE 3 MAP DECISIONS ARE NOW SETTLED FROM CODE + PROD DATA (the audit had them as open questions):
1. Registry key — confirmed correct as ('DatastorePositions','openroad'): is_snowflake_routable is called with self.__class__.__name__ from datastore_positions.py:92 / datastore_transactions.py:110, where self IS DatastorePositions. The openroad-specific DatastoreStandardizedPositionsOpenroad is a generation-side class and never reaches the routing check. The audit's worry was unfounded.
2. first_purchase_* -> PURCHASE_DATE / PRINCIPAL_AT_PURCHASE / PRICE_AT_PURCHASE (sofi-shaped, NOT northpond's origination-anchored shape). Mechanism: base_datastore_standardized_positions_foursight NULLs all three, openroad never calls add_purchase_fields (its PRE_GENERATED_FILENAMES has no 'first_seen'), and datastore_standardized_positions.py:574-585 backfills each from its purchase_* counterpart. Prod agrees: 35/35 loans have exactly 1 fund and 1 purchase_date. => openroad stays OUT of HISTORY_DERIVED_PLATFORMS.
3. NO account_name rename — NEW FINDING, differs from sofi/prosper/marlette/happymoney/northpond which all map account_name->ACCOUNT_ID. The OpenRoad loan tape's raw_record has 50 columns including account_id ('Edge - ORL') but NO account_name column at all, so legacy returns NULL; the NaN fill matches. Mapping it would invent a value. openroad behaves like upgrade here.
4. transactions PLATFORM_NULL_COLUMNS not needed: legacy and silver both take account_id from the payments file; prod shows 'Edge - ORL' on both sides, single fund efhyf, no fund movement (unlike northpond).

VERIFIED LIVE against prod through the legacy interface (DatastorePositions(platforms=['openroad'], source='snowflake').DATA) on the 8 as-of dates silver holds: 280 rows/35 loans; first_purchase_date==purchase_date 280/280; principal and price likewise; account_name all NaN; only 5 legacy columns NaN-filled (account_name, errors, p_prob_at_purchase, p_ytm_at_purchase, valuation_at_purchase — the Foursight base NULLs p_prob/p_ytm for openroad anyway). DatastoreTransactions routing returns 7 rows, 18/18 columns non-null. This is SHAPE validation only, not row-level parity.

ENV NOTE for whoever runs this next: the legacy datastore stack cannot be imported from repos/efp/.venv or a uv orchestration env (no dask/distributed/GitPython/mypy-boto3-*). It DOES import cleanly under the notebook conda env /home/abhishek/.conda/envs/abhishek_env_dev/bin/python3.11 with PYTHONPATH=<worktree>:<worktree>/lib. The dataframe attribute is .DATA, not .df.
- 2026-07-31T22:05Z [claude-code] 2026-08-01: PR #6133 description trimmed to 3 bullets on Abhishek's instruction (same treatment as #6128). REMOVED from the PR body: the 'Do not merge yet' section (the 280-rows-vs-1,101-files evidence and the 4 ordered prerequisites) and the validation table. The merge blocker is now signalled ONLY by the PR being a draft — it is NOT written anywhere on GitHub. If anyone marks #6133 ready without running the backfill + parity first, source='snowflake' will silently serve 8 of ~1,100 days of OpenRoad positions and 7 transaction rows. Prerequisites and evidence are preserved in the 22:03Z log entry above.
- 2026-08-03T13:44Z [claude-code] *** MERGE GUARD IS GONE — CHECK THIS BEFORE ANYTHING ELSE (2026-08-03 19:12 IST) ***
PR #6133 is now **draft=false** (last updated 2026-07-31 22:06Z). The 22:05Z entry above recorded that the 'Do not merge yet' section and the 4 ordered prerequisites had been REMOVED from the PR body, leaving draft status as the ONLY signal that it must not merge. That signal no longer exists. Current GitHub state: OPEN, not a draft, reviewDecision=REVIEW_REQUIRED, mergeStateStatus=BLOCKED — so branch protection is the only thing still holding it, and one approval clears it.
THE HAZARD, unchanged: steps 2-6 of the ordered plan (backfill -> silver rebuild -> parity) were NOT done as of the last entry. The registry sets deprecate_after=2026-08-03, i.e. TODAY. If this merges before the backfill, source='snowflake' silently serves **8 of ~1,100 days** of OpenRoad positions and **7 transaction rows** through the legacy DatastorePositions/DatastoreTransactions interface — a silent, near-total data loss for anything reading that path, with nothing on the PR to warn a reviewer.
Whoever picks this up: either re-add the 'Do not merge yet' note to the PR body, or convert it back to a draft, or complete the backfill+parity today. Linear DEV-1486 is 'In Review' as of 2026-07-31 22:16Z, which reads as ready and is misleading.
Validation done so far is SHAPE only (280 rows/35 loans over the 8 as-of dates silver holds), never row-level parity.
- 2026-08-03T17:13Z [claude-code] 2026-08-03: Resolved merge conflicts on PR #6133 — now MERGEABLE (was CONFLICTING/DIRTY). Rebased onto master, new SHA 495cc8d43 (was 46f103101), diff 2 files +31/-0 (was +32). Note #6133 is no longer a draft — someone marked it ready.

CONFLICT CAUSE + THE REAL FINDING: two deprecations landed while this sat — #6130 (upstart) and #6132 (anchored). #6132 did NOT just append; it REFACTORED positions_snowflake_map.py. COMMON_RENAMES now carries first_purchase_date -> PRIOR_PURCHASE_DATE, principal_at_first_purchase -> PRIOR_PRINCIPAL_AT_PURCHASE, original_markup -> PRIOR_PRICE_FRAC, fully_paid_date, transfer_out_date for ALL platforms, plus a new _FIRST_PURCHASE_FALLBACKS that does PRIOR_x.combine_first(current_x). price_at_first_purchase gets a dedicated branch (PRIOR_PRINCIPAL_AT_PURCHASE * PRIOR_PRICE_FRAC, else PRICE_AT_PURCHASE). HISTORY_DERIVED_PLATFORMS IS GONE ENTIRELY. sofi/prosper/marlette/happymoney entries were reduced to just account_name.

=> All three of my explicit openroad renames were made redundant. Keeping them would have been ACTIVELY WRONG, not merely noisy: the fallback only fires when renames.get(col) == fallback[0] ('PRIOR_PURCHASE_DATE'), so an explicit 'first_purchase_date': 'PURCHASE_DATE' BYPASSES the shared mechanism — same answer today (priors all NULL) but silently divergent the moment openroad ever gets a prior transfer. Resolved by making the openroad entry COMMENT-ONLY, like upgrade's and anchored's.

Verified in prod 2026-08-03: PRIOR_PURCHASE_DATE / PRIOR_PRINCIPAL_AT_PURCHASE / PRIOR_PRICE_FRAC / PRIOR_FUND are NULL on 280/280 openroad rows; PURCHASE_DATE / PRICE_AT_PURCHASE / MARKUP 0 NULL. Re-ran the live routing check after the rebase: byte-identical results to before (first_purchase_date==purchase_date 280/280, principal and price likewise, account_name all NaN, same 5 NaN-filled columns) — so the resolution is behaviour-preserving and now goes through the shared path.

Commit message and PR body both rewritten (the old ones cited HISTORY_DERIVED_PLATFORMS and the 3 renames, all stale).

STILL TRUE AND STILL NOT ON GITHUB: the backfill + parity prerequisites. mergeStateStatus is BLOCKED (branch protection/checks), not conflict.
- 2026-08-10T14:46Z [claude-code] *** PR #6133 MERGED 2026-08-03 17:23Z *** — the merge this item repeatedly warned against went ahead, and nothing has been logged here since.
Recap of why that was flagged: the 'Do not merge yet' section and the 4 ordered prerequisites were deliberately stripped from the PR body (07-31 22:05Z entry), leaving draft status as the only signal; the PR was then marked ready, and it merged the next working day. The registry entry sets deprecate_after=2026-08-03, so openroad DatastorePositions/DatastoreTransactions now route to Snowflake in prod.
WHAT WAS NEVER CONFIRMED DONE — steps 2-6 of the ordered plan: the bronze/silver backfill, the silver rebuild, and row-level parity. The only validation on record is SHAPE validation over the 8 as-of dates silver held (280 rows / 35 loans, 7 transaction rows), explicitly 'not row-level parity'.
THE EXPOSURE, if the backfill never ran: source='snowflake' serves ~8 of ~1,100 days of OpenRoad positions through the legacy interface — dashboards and any EDGEX/ABS consumer reading that path see a near-empty history with no error. Compounding it, [[wm-4s2sad]] records that GOLD.POSITIONS_COMPARISON_DAILY — the job that would catch exactly this — has written nothing since 2026-07-20, so the usual detector is blind.
FIRST ACTION FOR WHOEVER PICKS THIS UP: do not re-plan, just measure. Count rows/as-of-dates behind DatastorePositions(platforms=['openroad'], source='snowflake') against the ~1,100 legacy files. If it is still 8 dates, this is a live prod data gap, not a backlog item. Env note for the check is in the 07-31 22:03Z entry (conda env abhishek_env_dev, PYTHONPATH=<worktree>:<worktree>/lib, attribute is .DATA).
- 2026-08-12T13:03Z [claude-code] PROD MEASURED 2026-08-12 (the 'first action: do not re-plan, just measure' from the 2026-08-10 entry is now DONE). THE EXPOSURE IS REAL AND LIVE.

DEV-1486 is marked Done (2026-08-03T17:31Z), PR #6133 merged 2026-08-03T17:23Z, and openroad IS in the registry on origin/master (datastore_deprecations.py:142 DatastorePositions, :149 DatastoreTransactions; positions_snowflake_map.py:139 comment-only entry). So source='snowflake' routing is LIVE in prod. The backfill it depended on never ran.

MEASUREMENTS (PROD, 2026-08-12 06:00 UTC, via ~/bin/sqlrun.py on dpx):
- S3 s3://efp-raw/statements/openroad/ = 2,276 files (LoanTape 1,115 / Payments 1,094 / Transactions 29 / DealsFunded 33).
- bronze.statement_files openroad = 121 rows only: positions 44 (2026-06-29..08-11), payments 44 (2026-06-29..08-11), purchase_tape 33 (2023-07-13..2024-12-14). ZERO 'transactions' files ever registered. => the registry backfill (ordered-plan step 2) was NEVER run; bronze only picked up files forward from go-live.
- bronze.statement_rows openroad: positions 1,540 rows/44 dates, payments 35 rows/22 dates, purchase_tape 38 rows/33 dates.
- silver.positions openroad = 280 rows / 35 loans / 8 dates, 2026-06-29..**2026-07-06**. STALE BY 37 DAYS while bronze has positions through 2026-08-11 => the silver chain is not just un-backfilled, it has stopped advancing. Every other platform is current: anchored 08-11 (1,119 dates), prosper 08-11 (1,990), sofi 08-11 (589), northpond 08-11 (763), marlette 08-10 (1,405), happymoney 08-10 (475), upgrade 08-07 (1,888), lc 08-02 (3,349), upstart 07-26 (1,325). openroad's 8 dates is the worst by two orders of magnitude.
- silver.transactions openroad = 7 rows / 6 loans / 4 dates (2026-07-01..07-06). silver.openroad_stmt_transactions = 0 ROWS.
- silver.transfers openroad = 35 rows, EFP_ID NULL 35/35, FROM_FUND NULL 35/35 (unchanged since the 07-29 audit).

THE DETECTOR IS ALIVE AND HAS BEEN SCREAMING — correcting [[wm-4s2sad]] for openroad: GOLD.POSITIONS_COMPARISON_DAILY is NOT dead, it ran 2026-08-11 06:03:57 with as_of_date through 2026-08-09 (142 rows for openroad). Its verdict: EXTRA_IN_SNOWFLAKE=0, EXTRA_IN_DATASTORE=35, COMMON_COUNT=0 on **141 of 142 dates** (2026-03-21..2026-08-09). Exactly ONE date matches — 2026-07-06 (0/0/35). So the board has recorded total openroad divergence continuously for five months, including every day since the deprecation merged.
ANOMALY WORTH CHASING: silver.positions HAS 35 rows on each of 2026-06-29..07-05, yet the comparison counts those same dates as 35 datastore-only / 0 common. Only 07-06 joins. Either the comparison's join key or its snapshot selection is off for openroad, or those 7 dates fail the join on a column the tool keys on. Unexplained — do not quote '1 of 142' as pure data absence without resolving this.

NULL PROFILE, silver.positions openroad (n=280): CREDIT_SCORE 280/280 NULL, CREDIT_SCORE_AT_PURCHASE 280/280, FIRST_PAYMENT_DUE_DATE 280/280, ANL 280/280, IRR 280/280. PURCHASE_DATE and ZIP_CODE 0 NULL. Single fund, single account_id — unchanged.
PREDICTIONS still broken as of 07-29: silver.predictions openroad 2,507 rows / 35 ids, max as_of_date 2024-12-12, still APP_ID-keyed (openroad_4675720, _4713755, _4775948...) vs positions' openroad_5865766, _4994794... => 0 of 35 ids join. silver.predicted_cashflows openroad 2,507 rows, FEES 2,507/2,507 NULL, NET_CASH_FLOW 2,507/2,507 NULL, RECOVERY 2,367/2,507 NULL, last loaded_at 2026-07-07 14:02. DEV-1331 was closed Done 2026-08-03 but prod was never re-materialized — the NaN-config corruption PR #5974 fixed is still sitting in prod data.

LINEAR BOOKKEEPING GAP: the 'Deprecate datastores' milestone (b4cc3095, target 2026-08-03) STILL reads 0% and still contains ZERO issues — DEV-1486 was created and closed but never attached to the project or the milestone. list_issues on 'OpenRoad Data Ingestion' returns only DEV-1331, 1350, 1154, 1150, 1118, 1070. So Abhijeet's project view shows the deprecation as not started, while prod has already been switched over. Both readings are wrong in opposite directions.
- 2026-08-12T13:09Z [claude-code] FILE INVENTORY RESOLVED 2026-08-12 — Abhishek pushed back that 2,276 files vs 35 loans looked wrong. He is right, and the earlier framing was misleading. The 35-loan portfolio is CORRECT AND COMPLETE; the files are DAILY SNAPSHOTS, so the gap is history DEPTH, not missing loans.

PROOF 35 IS THE WHOLE PORTFOLIO: bronze.statement_rows openroad positions = exactly 35 rows on every one of the 44 as-of dates (1,540/44 = 35.0). silver.openroad_stmt_purchase_tapes = 35 rows from 33 funding tapes. Funding tapes stop 2024-12-14 and Transactions files stop 2024-12-18 => OpenRoad closed to new purchases in Dec 2024; the 35 loans have just been serviced and reported daily since.

S3 BREAKDOWN (s3://efp-raw/statements/openroad/, 2,276 objects) vs bronze.statement_files:
  LoanTape_Edge_Orl_*.csv   1,115 files, 2023-07-24..2026-08-11 (daily) | bronze 44 | MISSING 1,071
  Payments_Edge_Orl_*.csv   1,094 files, 2023-08-14..2026-08-11 (daily) | bronze 44 | MISSING 1,050
  Transactions_Edge_Orl_*   29 files, 2023-07-25..2024-12-18 (sporadic) | bronze  0 | MISSING 29
  *EdgeFocusDealsFunded_*   33 files, 2023..2024-12-14 (purchase tape)  | bronze 33 | COMPLETE
  LoanTape_Edge_*.csv (no _Orl) 4 files, 2023-07-20..23, 1,335 bytes each — early naming variant; the job docstring says it parses 'LoanTape_Edge[_Orl]_' so these ARE in scope.
  '*_Edge_Orl*.csv' 1 object, 0 bytes, created 2026-08-11 10:36 — a literal unquoted shell glob someone uploaded by accident. Junk. Delete it, and make sure the backfill's matcher does not choke on it.
So the only file type fully ingested is the purchase tape. Bronze holds 44 of ~1,119 position days = 3.9%.

EXPECTED AFTER BACKFILL: ~1,119 as-of dates x 35 loans = ~39,000 rows in silver.positions (vs 280 today). Consistent with the earlier dev-side estimate of ~32K rows/~1,080 dates. Volume is trivial — the files are 1.3KB-16.6KB, ~15MB total.

SEQUENCING CORRECTION: backfill is NOT the first move. See [[wm-85nuv4]] — the openroad silver job has not run since 2026-07-07, so backfilled files would land in bronze and stop there. Bronze ingest is healthy and current; the dead consumer is the silver job.
- 2026-08-20T11:52Z [claude-code] 2026-08-20 17:20 IST: Abhishek says the OpenRoad datastore deprecation is already done. Marking done on his confirmation — note the Linear milestone may still read 0% and need updating separately.
