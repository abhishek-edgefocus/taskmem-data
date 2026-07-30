---
id: wm-5z3pjt
type: task
title: Map EDGEX 2026-1NN Oliv investor IDs (INV105 / INV103) into the northpond fund mapping
status: next
priority: p1
size: m
people: [Dustin, Abhijeet]
tags: [northpond, edgex]
links: [parent:wm-j523sq]
created: 2026-07-28T11:01:04Z
updated: 2026-07-30T16:19:33Z
source: claude-code
---

Abhijeet asked in #platform-data-owners (2026-07-28 16:26 IST) that each platform owner complete the EDGEX 2026-1NN investor-ID mapping; Dustin marked the ID list complete 2026-07-28 04:31 IST. Oliv/NorthPond IDs: EDGEX Purchaser I = `INV105`, EDGEX Grantor Trust = `INV103`.

Current state (verified on ~/repos/efp master, 2026-07-28): NorthPond has NO investor-ID concept at all. `edgefocus/transformations/silver/statement_rows/northpond/constants.py` maps fund by SFTP ACCOUNT_NAME only — `NORTHPOND_ACCOUNT_FUND_MAP = {ef_northpond: experimental, northpond_efhyf: efhyf}`. No EDGEX account exists in `configs/default_passwords.json` for northpond, and INV105/INV103 appear nowhere in the repo. The purchase-tape schema (`stmt_purchase_tapes.py`) has no investor/account column either; FUND is derived by the purchase-tape membership IFF in `FUND_WITH_PURCHASE_TAPE_EXPR`.

Open question to resolve first: how will EDGEX-purchased Oliv loans be distinguished — a new SFTP account/sftp_key (e.g. `northpond_edgex*`) like the efhyf one, or a new investor_id field on the Oliv tape? Ask Dustin/Nate.

Cross-platform gaps worth flagging, not ours to fix (shared code):
- Grantor Trust IDs are unmapped for EVERY platform (Upgrade 9417954, Prosper 15983181, Oliv INV103 all absent from the fund maps); there is no grantor-trust FUNDS constant.
- `stmt_utils.resolve_edgex_purchaser_fund` has no 2026-1NN cutoff: EDGEX_PURCHASER for dates >= 2026-02-01 still resolves to edgex2026PT2, so a 1NN rollover date is needed once purchasing starts (deal target close 2026-07-28).
- `FUNDS.EDGEX_2026_1 = 'edgex20261NN'` already exists and is in EDGEX_FUNDS.

Ref: https://edgefocuspartners.slack.com/archives/C08J572GQBE/p1782766983577449?thread_ts=1782766983.577449&cid=C08J572GQBE

## Log
- 2026-07-28T11:42Z [claude-code] Asked Nate/Trishit in the group DM (C0BJ1M304BU, 2026-07-28 17:06 IST). Trishit replied 17:08: 'Don't think any actions are needed on this. This is generally a constant defined in our codebase to populate in internal tables.' Nate has not replied.

Reading: the investor ID is NOT something Oliv will send — it's a label we stamp per fund on our side, so we are not blocked waiting on a tape change. But this does NOT clear the real code gap: northpond/constants.py FUND_WITH_PURCHASE_TAPE_EXPR hardcodes FUNDS.EFHYF for ANY loan appearing on silver.northpond_stmt_purchase_tapes with PURCHASE_DATE <= AS_OF_DATE. If EDGEX 2026-1NN Oliv purchases arrive on that same purchase tape, they will be labelled efhyf, not edgex20261NN. Needs a follow-up asking how the EDGEX purchases arrive (same purchase tape / separate file / separate SFTP account) — that is the fund-attribution question, separate from the investor ID.
- 2026-07-28T11:49Z [claude-code] Nate Wong replied 2026-07-28 17:14 IST in the same thread:
1. Agrees no entity delineation exists in any reporting to date.
2. Expects effectively ALL loans held by INV103 (Grantor Trust); INV105 is the exception. So the INV103/INV105 split is a 'less critical' gap on Day 1.
3. Oliv has NOT yet extended their Nelnet loan + transaction files to us (prioritization only). These are the equivalent of the files shared today from FCC, their previous servicer. The Nelnet LOAN FILE carries the investor tag — i.e. that feed is what properly solves the INV103/INV105 split.
4. Other post-launch solutions possible depending on use case.
His proposal: (a) everything INV103 by default, (b) punt INV103-vs-INV105 for a couple weeks, (c) start work on sharing the Nelnet loan + transaction files. Asked Abhishek for his view.

STATUS: the investor-ID half is effectively settled — default INV103, no tape change needed now. STILL OPEN: neither Nate nor Trishit addressed EDGEX-vs-EFHYF fund attribution, which is the urgent one since purchasing starts today and FUND_WITH_PURCHASE_TAPE_EXPR hardcodes efhyf for every loan on the Oliv purchase tape.
- 2026-07-28T12:19Z [claude-code] RESOLVED (Abhishek, 2026-07-28): all Oliv loans purchased from today onward belong to the EDGEX fund, so there is no EDGEX-vs-EFHYF discriminator needed on the purchase tape and no question to ask Oliv. The fund split is a DATE CUTOFF we own: purchase-tape loans with PURCHASE_DATE < 2026-07-28 -> efhyf, >= 2026-07-28 -> edgex20261NN.

Remaining code work: FUND_WITH_PURCHASE_TAPE_EXPR in edgefocus/transformations/silver/statement_rows/northpond/constants.py currently returns FUNDS.EFHYF unconditionally for any loan on silver.northpond_stmt_purchase_tapes with PURCHASE_DATE <= AS_OF_DATE. Needs the date-based branch. Caveat to confirm with Trishit eventually: a pure date rule breaks if EFHYF resumes buying Oliv loans later.
- 2026-07-28T17:40Z [claude-code] CODE STATE RE-VERIFIED ON MASTER 2026-07-28 — still genuinely open, and this is today's live risk. Read edgefocus/transformations/silver/statement_rows/northpond/constants.py at origin/master: FUND_WITH_PURCHASE_TAPE_EXPR is unchanged and still returns FUNDS.EFHYF unconditionally for any loan whose LoanNumber appears on silver.northpond_stmt_purchase_tapes with TRY_TO_DATE(PURCHASE_DATE) <= AS_OF_DATE. There is no date branch and no open PR touching it (checked all of Abhishek's PRs).
So the rule settled on 2026-07-28 — purchase-tape loans before today -> efhyf, on or after today -> edgex20261NN — exists only as a decision, not as code, while EDGEX 2026-1NN purchasing starts today. Every Oliv loan purchased from now on will be labelled efhyf until this lands.
The investor-ID half remains settled per Nate (default INV103, no tape change needed), so this item is now purely the fund-attribution code change.
- 2026-07-29T17:02Z [claude-code] VERIFIED 2026-07-29 against origin/master (0b025f36e) + prod Snowflake. Trishit's 'constant in our codebase, no action needed' is half right.

TRUE: the investor ID is not a field Oliv sends; every platform stamps fund from a codebase constant. FALSE for northpond: those constants are all keyed on a discriminator that exists in the incoming data, and northpond has none.
- upgrade/constants.py UPGRADE_INVESTOR_FUND_MAP: investor_id, taken from the ACCOUNT_NAME suffix (SPLIT_PART(ACCOUNT_NAME,'_',-1)). 9417954 -> EDGEX_2026_1 landed in #6060.
- prosper/constants.py PROSPER_FUND_BY_ACCOUNT: ACCOUNT_NAME = account number. 15983181 -> EDGEX_2026_1 landed in #6070.
- marlette/constants.py generate_fund_mapping: SUBPOOL. 241 -> EDGEX_2026_1 landed in #5818.
- happymoney/constants.py HAPPYMONEY_PORTFOLIO_FUND_MAP: PORTFOLIOID. Dustin's 2026-1NN grantor trust = 70 is NOT mapped, in silver or in legacy base_statement_happymoney.py (only 54/56/60/62/64). Cross-platform gap, not ours.
- northpond: bronze.statement_rows confirms ALL SIX statement types (positions, issuance, issuance_v2, transactions, transaction_boards, payment_configuration) arrive under a single ACCOUNT_NAME 'ef_northpond'. There is no investor/account/subpool/portfolio key to hang a mapping on.

CORRECTION to the 2026-07-28 log entry: EDGEX Oliv loans will NOT be mislabelled efhyf. prod.silver.northpond_stmt_purchase_tapes is frozen — MAX(purchase_date) = MAX(as_of_date) = 2025-06-17, 372 loans, nothing since. So FUND_WITH_PURCHASE_TAPE_EXPR's IN-subquery misses new loans and they fall through to FUND_MAPPING_EXPR -> ef_northpond -> 'experimental'. Live proof: prod.silver.positions for northpond as of 2026-07-29 is only efhyf/northpond_efhyf (372 loans) and experimental/ef_northpond (343).

ALSO CORRECTED: stmt_utils.resolve_edgex_purchaser_fund DOES now have the 1NN cutoff (date >= 2026-07-28 -> edgex20261NN), added by #5942 'DEV-1394: edgex20261NN purchaser cutover 2026-07-28'. The earlier note saying it was missing is stale. It only helps platforms that route through EDGEX_PURCHASER though — northpond does not.

NOT YET URGENT: prod.silver.positions has ZERO rows in edgex20261NN on any platform, and the only purchases in silver.transfers since 2026-07-20 are upgrade->efhyf (through 07-28). 1NN purchasing has not actually started anywhere, so nothing is mislabelled yet.
- 2026-07-29T18:09Z [claude-code] PR OPENED 2026-07-29: https://github.com/edgefocus/efp/pull/6085 — 'DEV-1474: Attribute Oliv purchase-file loans to EDGEX 2026-1NN via account INV103'.

Design Abhishek chose (over the pure date-cutoff rule logged 2026-07-28): derive fund from the purchase file's own ACCOUNT_NAME, keyed on the investor ID, with the date only as a guard.
- bronze parsing rule for purchase_file/v0 (added by #6013) now uses account_name='INV103' instead of 'northpond_efhyf'.
- NORTHPOND_ACCOUNT_FUND_MAP gains INV103 -> edgex20261NN; ACCOUNT_ID falls out of the inverse map, so silver.positions ACCOUNT_ID = INV103 for EDGEX Oliv loans. This closes the NorthPond half of Abhijeet's #platform-data-owners investor-ID ask.
- FUND_WITH_PURCHASE_TAPE_EXPR rewritten from IFF(loan on tape -> hardcoded 'efhyf') to COALESCE(MAX_BY(FUND, PURCHASE_DATE) of the latest purchase-file row, account map).
- NORTHPOND_EDGEX_PURCHASE_START = 2026-07-28 guards it via three new ValidationRules on NorthpondStmtPurchaseTapes.
- INV105 deliberately left unmapped (Nate: everything is INV103; the split comes from the Nelnet loan file, wm-gj5tkx / DEV-1481).

Proof: replaying old vs new expression over all 715 loans on the 2026-07-29 tape gives 0 mismatches (372 efhyf, 343 experimental, 0 NULL) — inert until INV103 files arrive. Synthetic INV103 row resolves to fund edgex20261NN + account_id INV103. 2359 passed / 1 skipped in edgefocus/transformations.

Side effect to watch: v0 CSV and Pool N xlsx no longer share a supersession group (that key includes account_name). Intended — different books — and the date guard now catches the overlap case instead.

NO LINEAR TICKET EXISTS for this; PR is titled DEV-1474 as the natural completion of the purchase-path work. Abhishek to create/retitle if he wants a dedicated ticket.
- 2026-07-29T18:38Z [claude-code] PR #6085 review round 1 (2026-07-30): Cursor Bugbot + Sentry both flagged the new purchase-tape guards as HIGH — real bug, fixed in e28f6697c.

Transform._apply_validations builds every row-level ValidationRule as 'SELECT EFP_ID, AS_OF_DATE, <msg> FROM new_silver_data WHERE NOT (<check>)'. silver.northpond_stmt_purchase_tapes has AS_OF_DATE but NO EFP_ID (verified via information_schema) — its grain is one purchase-file row keyed on LOAN_ID. The projection is evaluated regardless of whether any row violates the check, so it fails at SQL COMPILATION on every purchase-tape run producing rows, not just on violation (the bots said 'when a validation fails'; it is worse than that). Reproduced against the live table: row-level form raises SQL compilation error.

Fix: converted all three guards to validation_type='batch', which supply their own identifier column, so LOAN_ID AS EFP_ID. Entirely inside the northpond transform — no shared-framework change. Messages now interpolate the offending PURCHASE_DATE / ACCOUNT_NAME.

Proof: the exact UNION ALL shape _apply_validations builds compiles and returns 0 rows over all 450 existing purchase-tape rows; all 3 guards fire on a synthetic batch (pre-cutover EDGEX row, post-cutover EFHYF row, unmapped account, plus one valid row left untouched). Added TestPurchaseTapeCutoverGuards pinning batch type + the (EFP_ID, AS_OF_DATE, ERROR_MESSAGE) contract. 2362 passed / 1 skipped.

GENERAL LESSON for any parsed silver.<platform>_stmt_* table: row-level ValidationRules only work on tables that carry EFP_ID. Parsed stmt tables generally do not — use batch rules there.
- 2026-07-29T20:24Z [claude-code] PR #6085 review round 2 (2026-07-30): Sentry flagged test_fund_uses_in_subquery_against_silver (TestPositionsSql + TestTransactionsSql) as HIGH, claiming it 'will fail' against the new subquery. FALSE — the tests pass, locally (2362) and in CI on e28f6697c.

But the underlying point was valid in a different way: the assertion was VACUOUS. Both tests asserted 'IN (' in the generated SQL from when the fund expression used an IN subquery. After the MAX_BY rewrite the only 'IN (' left in the generated SQL is the unrelated as_of_date IN ('2026-05-18') date filter (verified by regex-scanning every occurrence in the rendered SQL), so it passed on a coincidence and no longer guarded the named behaviour.

Fixed in 06d677f25: renamed to test_fund_uses_correlated_subquery_against_silver and asserted the real markers — MAX_BY(FUND, TRY_TO_DATE(PURCHASE_DATE)) and WHERE LOAN_ID = src.RAW_RECORD:"LoanNumber"::VARCHAR — keeping the table + as-of-date assertions.

Cursor's original EFP_ID comment now shows against e28f6697c but that is GitHub repositioning the unresolved thread, not a new finding: cursor[bot] has no review on e28f6697c and its check passed. Sentry marked its own copy 'Resolved in e28f669'.

CI on e28f6697c: Run Tests success, Select tests success, Cursor Bugbot success, Seer neutral, integration tests skipped. mergeStateStatus BLOCKED = awaiting human review approval, not a failing check.
- 2026-07-29T20:53Z [claude-code] PR #6085 FINAL STATE 2026-07-30: all bot findings closed, CI fully green on head 06d677f25.

3 commits: ce703774d (feature), e28f6697c (batch validations fix), 06d677f25 (re-point vacuous tests). 6 files, +247/-38.

Checks on 06d677f25: Run Tests success, Select tests success, Cursor Bugbot success, Seer Code Review success, integration tests skipped.

Outstanding bot comments: NONE that are live. Two threads anchored to head are both stale artifacts — cursor[bot]'s EFP_ID comment has original_commit_id=ce703774d (GitHub repositioned the unresolved thread; cursor filed no review on either later commit and its check passes), and sentry[bot]'s is literally 'Resolved in 06d677f'. Sentry also marked the earlier one 'Resolved in e28f669'.

mergeState=BLOCKED / reviewDecision=REVIEW_REQUIRED — needs a human approver, no failing check. Abhishek to request review. Also still to do before merge per his style: swap the inline SQL/result markdown tables in the PR body for Snowflake screenshots with query+grid in frame; DAG line is correctly 'DAG - unchanged.'
- 2026-07-30T13:40Z [claude-code] PR #6085 review rounds 3-4 (2026-07-30). Four human-relayed review points, all four confirmed real, plus one follow-on from Sentry.

ROUND 3 (commit 10e740c3e):
1. NULL/unparseable PURCHASE_DATE — REAL and worse than flagged. A row with a valid INV103 account (FUND=edgex20261NN) but blank/malformed PURCHASE_DATE passes all three original guards (both date comparisons go NULL), then vanishes TWICE: FUND_WITH_PURCHASE_TAPE_EXPR filters it on TRY_TO_DATE(PURCHASE_DATE) <= AS_OF_DATE so the loan falls back to experimental, AND transfers._purchase_tape_leg drops it on the same TRY_TO_DATE(...) IS NOT NULL predicate. Result: an EDGEX loan labelled experimental with no purchase event and no error. Added guard 4.
2. Stale docstrings — REAL. stmt_positions.generate_sql and stmt_transactions.generate_sql both still said 'efhyf if the loan appears in silver.northpond_stmt_purchase_tapes'. Neither file was otherwise in the diff. Rewritten.
3. MAX_BY tie-break — correctly assessed as prevented; cross-fund ties require same LOAN_ID + same PURCHASE_DATE with different funds, which the cutover guards reject. Documented only, no code change.
4. Loan-level exclusivity across the two feeds — REAL latent gap. transfers._purchase_tape_leg hardcodes FROM_FUND=experimental, so a loan sold EFHYF->EDGEX would emit a second event claiming it came from experimental. Added guard 5 as a tripwire.

ROUND 4 (commit 515f1250c): Sentry then flagged that guard 5 only checks the COMMITTED table. Real — validations run before delete_and_insert, so a loan arriving under two funds inside one batch (multi-date backfill, or first run ingesting both feeds) escapes. Added guard 6, a window over new_silver_data (MIN(FUND) != MAX(FUND) OVER (PARTITION BY LOAN_ID)).

SNOWFLAKE CONSTRAINT worth remembering: guards 5 and 6 CANNOT be merged into one rule. Snowflake rejects both single-query forms with '002031 Unsupported subquery type cannot be evaluated' — (a) a self-correlated EXISTS against the new_silver_data CTE, and (b) a correlated EXISTS against a real table issued from a derived table carrying window functions. Verified directly against Snowflake; recorded in a code comment so nobody retries the merge.

Baseline that made all of this safe to add: existing tape is 372 rows, 0 NULL dates, 0 unparseable, 372 distinct LOAN_IDs. All six guards compile in the exact UNION ALL shape _apply_validations builds and return 0 rows on prod. 2364 passed / 1 skipped.
- 2026-07-30T15:52Z [claude-code] PR #6085 round 5 (2026-07-30) — SELF-CAUGHT PRODUCTION DEFECT while verifying the SQL queries at production fidelity. Fixed in 2edcc9881.

Guard 5 (committed-fund conflict, added in 10e740c3e) used a correlated EXISTS against silver.northpond_stmt_purchase_tapes. It compiles for SOME batches and fails for others with '002031 Unsupported subquery type cannot be evaluated'. Snowflake decides whether it can decorrelate from the chosen plan, and the plan depends on the temp table contents — the SAME rule passed a 1-row temp table and failed an 8-row one with identical column types. Reproduced deterministically.

WHY EARLIER VERIFICATION MISSED IT (important methodology lesson): every prior check used new_silver_data = silver.northpond_stmt_purchase_tapes, i.e. the target table itself. That makes the EXISTS a SELF-join, which always plans. In production new_silver_data is the TEMP table — a DIFFERENT table from the one the EXISTS reads — which is the failing shape. Validating a batch rule against the target table is NOT equivalent to production; materialise the batch as a separate real table (a literal-CTE also does not reproduce it, it hits a different planner path).

Fix: rewrite as SELECT DISTINCT ... FROM new_silver_data n JOIN silver.northpond_stmt_purchase_tapes pt ON pt.LOAN_ID = n.LOAN_ID AND pt.FUND IS DISTINCT FROM n.FUND. Joins always plan. DISTINCT because a loan may conflict with several committed rows and should raise one error. Added test_committed_fund_conflict_uses_a_join_not_a_correlated_exists so the EXISTS cannot return.

Verified with the batch materialised as a real table: 1-row batch -> 1 violation; 8-row batch (one violating row per guard + a clean EDGEX row) -> previously failed to compile, now 7 rows with every guard firing correctly and the clean row untouched; all 6 guards vs the 372 real prod rows -> 0. 2365 passed / 1 skipped.

ALSO VERIFIED this round: the PR body SQL runs verbatim and reproduces its stated table exactly (715 loans / 0 mismatches / 372 efhyf / 343 experimental / 0 null). The PR body's second claim (synthetic INV103 -> edgex20261NN + account_id INV103) had NO sql block in the body — only a result table; a runnable query for it is at ~/claude-ws/oliv-edgex-fund/prsql_1.sql on dpx and confirms both values.
- 2026-07-30T16:19Z [claude-code] PR #6085 round 6 (2026-07-30), commit 74b84b076. Sentry (MEDIUM) flagged the intra-batch fund-conflict guard for reporting one error per ROW rather than per violation. Valid: the MIN/MAX window marks every row in the conflicting loan's partition, so an n-row conflict emitted n lines. The repeats were BYTE-IDENTICAL — the message names the loan and the two funds, never the row's own fund — so they added nothing and inflated the failure count _apply_validations reports. It was also inconsistent with the committed-fund guard beside it, which already had DISTINCT (added for a different reason: its JOIN fans out over multiple committed rows).

Added DISTINCT + test_both_fund_conflict_guards_deduplicate. 8-row synthetic batch now returns 6 rows instead of 7 (the duplicated loan reports once, every guard still fires exactly once, clean row untouched); prod still 0 across all six. 2366 passed / 1 skipped.

Running tally of PR #6085 review findings: 7 raised, 7 real, 7 fixed. Sources: Cursor 1, Sentry 4 (one of them false-in-its-stated-form but a real vacuous-test problem underneath), human-relayed 4 (counted in the same set), self-caught 1 (the guard-5 correlated-EXISTS planner defect, the most serious). No finding has been dismissed as invalid.
- 2026-07-30T16:19Z [claude-code] CORRECTION to the tally in the previous entry — it said '7 raised' but listed sources summing to 10. Both numbers were wrong. Accurate count of distinct findings on PR #6085, all real, all fixed, none dismissed:

1. EFP_ID crash in row-level validations (Cursor + Sentry, same finding, 2 reporters) -> e28f6697c
2. Vacuous 'IN (' test assertion (Sentry; false as stated — tests passed — but a real vacuous-guard problem underneath) -> 06d677f25
3. NULL/unparseable PURCHASE_DATE silent fallback (human-relayed) -> 10e740c3e
4. Stale docstrings in stmt_positions + stmt_transactions (human-relayed) -> 10e740c3e
5. MAX_BY tie-break (human-relayed; correctly assessed as already prevented — comment only, no code change) -> 10e740c3e
6. Loan-level exclusivity across the two feeds (human-relayed) -> 10e740c3e
7. Guard 5 missed intra-batch conflicts, only checked the committed table (Sentry) -> 515f1250c
8. Guard 5 correlated EXISTS is planner-dependent and fails to compile on some batches (SELF-CAUGHT while verifying the SQL at production fidelity; the most serious of the set) -> 2edcc9881
9. Intra-batch guard emitted byte-identical duplicate errors (Sentry) -> 74b84b076

TOTAL: 9 findings, 9 real, 9 addressed. By source: Sentry 4, human-relayed 4, Cursor 1 (shared with Sentry on #1), self-caught 1. Item 5 was resolved by documentation rather than a code change.
