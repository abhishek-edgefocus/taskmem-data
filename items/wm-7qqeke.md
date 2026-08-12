---
id: wm-7qqeke
type: task
title: Fix northpond FUND_WITH_PURCHASE_TAPE_EXPR hardcoded efhyf before Oliv EDGEX purchase files land
status: done
priority: p1
size: s
due: 2026-08-11
people: [Abhijeet]
tags: [northpond, edgex]
links: [relates:wm-5z3pjt, parent:wm-j523sq]
created: 2026-07-31T17:01:37Z
updated: 2026-08-12T13:28:41Z
source: claude-code
---

Follow-up to PR #6085 (merged scope: fund-map entries only). Confirmed real 2026-07-31, latent today.

edgefocus/transformations/silver/statement_rows/northpond/constants.py lines 43-53:
FUND_WITH_PURCHASE_TAPE_EXPR = IFF(loan IN (SELECT LOAN_ID FROM silver.northpond_stmt_purchase_tapes WHERE TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE), 'efhyf', FUND_MAPPING_EXPR)

The 'efhyf' is a hardcoded literal, so ANY loan on the purchase tape is labelled efhyf regardless of the ACCOUNT_NAME it arrived under. With INV103 -> edgex20261NN now in NORTHPOND_ACCOUNT_FUND_MAP, an EDGEX purchase produces INCONSISTENT silver:
- silver.northpond_stmt_purchase_tapes.FUND = edgex20261NN   (correct; stmt_purchase_tapes.py uses FUND_MAPPING_EXPR)
- silver.northpond_stmt_positions.FUND     = efhyf           (WRONG; stmt_positions.py:23 uses FUND_WITH_PURCHASE_TAPE_EXPR)
- silver.northpond_stmt_transactions.FUND  = efhyf           (WRONG; stmt_transactions.py:20)
- silver.positions.ACCOUNT_ID              = northpond_efhyf (WRONG; positions.py:94 account_id_from_fund_expr derives it from the wrong FUND)
- silver.transfers.TO_FUND                 = edgex20261NN    (correct; transfers.py:144 reads pt.FUND)
So transfers and positions DISAGREE on the same loan, which breaks the purchases join that supplies the *_AT_PURCHASE columns.

NOT reachable yet, which is why it was left out of #6085: the purchase tape is frozen (MAX(purchase_date)=MAX(as_of_date)=2025-06-17, 372 loans, all northpond_efhyf), no real purchase_file/v0 file has ever landed (S3 has only _test stubs), and the v0 parsing rule still tags files account_name=northpond_efhyf. It fires the moment Oliv delivers real EDGEX purchase files.

PROPOSED FIX (no date logic, respects the 'keep it simple' constraint) — take the fund from the purchase-tape row instead of hardcoding:
FUND_WITH_PURCHASE_TAPE_EXPR = COALESCE(
    (SELECT MAX_BY(FUND, TRY_TO_DATE(PURCHASE_DATE))
     FROM silver.northpond_stmt_purchase_tapes
     WHERE LOAN_ID = src.RAW_RECORD:"LoanNumber"::VARCHAR
       AND TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE),
    (FUND_MAPPING_EXPR))

Already validated against prod during the #6085 work: replaying old vs new over all 715 northpond loans on the 2026-07-29 tape gave 0 mismatches (372 efhyf, 343 experimental, 0 NULL) — a no-op on existing data, only changes behaviour once a non-efhyf purchase row exists.

Also still open and required for any of this to fire: confirm HOW INV103/INV105 reach ACCOUNT_NAME. Nothing sets it today.

## Log
- 2026-08-10T14:38Z [claude-code] NATE SET A LIVE DATE (C0BJ1M304BU, 2026-08-08 17:01 IST, ts 1786188718.575029): 'the plan/target is to produce the first live purchase file on Tuesday. We will finish setting up proper values for some fields that currently have stubs/placeholders (accrued interest, etc)'. Tuesday from that Saturday = 2026-08-11, i.e. TOMORROW relative to today 2026-08-10. This is the first real purchase file since Pool 6 (June 2025) and it lands at purchase_file/v0/2026/08/purchase_file_v0_YYYYMMDD.csv, ingested by rule northpond_purchase_tape_v0_csv.
Context: Abhishek sent the v0 sign-off 2026-08-08 03:15 IST ('the v0 file looks good - schema matches exactly what we ingest. We're on v0 for now and will move to the v1 schema later'); Nate reacted :thankyou:. Nate's stub-fix note covers accrued_interest and by implication outstanding_principal_balance_as_of_funding_date, but he did NOT mention the empty dti_ratio or the filename/content date skew (file named _20260723_ while purchase_date inside was 2026-07-24) — both still worth watching on the first live file.
DEADLINE FOR THIS ITEM IS NOW CONCRETE: the body says the FUND_WITH_PURCHASE_TAPE_EXPR hardcoded 'efhyf' bug 'fires the moment Oliv delivers real EDGEX purchase files'. That moment is 2026-08-11. If unfixed, the first live EDGEX purchase produces silver.northpond_stmt_positions.FUND=efhyf and silver.positions.ACCOUNT_ID=northpond_efhyf while stmt_purchase_tapes.FUND and transfers.TO_FUND say edgex20261NN — positions and transfers disagree on the same loan and the *_AT_PURCHASE join breaks. Fix before Tuesday.
- 2026-08-10T15:09Z [claude-code] DONE (code) 2026-08-10. Branch abhishek/dev-1509-rename-experimental-northpond-fund in an ISOLATED workspace ~/claude-ws/dev-1509/efp on dpx (fresh clone off origin/master d1e9c461c; no ~/repos* checkout touched). Commit 7aa88bd78, 2 files, +26/-16.

CHANGE: northpond/constants.py FUND_WITH_PURCHASE_TAPE_EXPR — replaced IFF(loan IN (SELECT LOAN_ID FROM silver.northpond_stmt_purchase_tapes WHERE PURCHASE_DATE <= src.AS_OF_DATE), 'efhyf', FUND_MAPPING_EXPR) with COALESCE((SELECT MAX_BY(FUND, TRY_TO_DATE(PURCHASE_DATE)) FROM silver.northpond_stmt_purchase_tapes WHERE LOAN_ID = src.RAW_RECORD:"LoanNumber"::VARCHAR AND TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE), (FUND_MAPPING_EXPR)). Comment rewritten to state behaviour only (no provenance, per the review convention). northpond_constants_test.py updated: the 3 tests that asserted the 'IN (' shape now assert the MAX_BY(FUND,...) shape, plus a new test_does_not_hardcode_a_fund guard.

VERIFIED: ruff format + ruff check clean, mypy clean, 171/171 northpond tests pass. SNOWFLAKE PROOF — replayed OLD vs NEW over the latest prod northpond positions tape: 715 loans, 0 mismatches, 0 NULL funds (efhyf->efhyf 372, experimental->experimental 343). No-op on current data; only changes behaviour once a non-efhyf purchase row exists.

STILL NOT PUSHED / NO PR — the branch also carries the DEV-1509 rename per Abhishek's instruction to do both in one PR, and DEV-1509 is blocked on a decision (see [[wm-qtjmcv]]).

REMAINING GAP unchanged and still required before the fund can actually be non-efhyf: NOTHING SETS ACCOUNT_NAME to INV103/INV105. The v0 parsing rule hardcodes account_name='northpond_efhyf', so even with this fix an EDGEX purchase still maps to efhyf. That is a separate change in the bronze parsing rule and it is the real Tuesday risk.
- 2026-08-10T15:35Z [claude-code] PR RAISED 2026-08-10: https://github.com/edgefocus/efp/pull/6208 carries this fix as commit 7aa88bd78, bundled with the DEV-1509 rename ([[wm-qtjmcv]]) per Abhishek. Awaiting review — needs to land before the first live EDGEX purchase file on 2026-08-11.
- 2026-08-10T15:52Z [claude-code] SPLIT OUT INTO ITS OWN PR 2026-08-10 (Abhishek: the combined PR carried too many changes). Now https://github.com/edgefocus/efp/pull/6209 — 'Fix northpond purchase-tape fund by reading it from the tape row instead of hardcoding efhyf', open, base master, head abhishek/northpond-purchase-tape-fund-from-tape-row, 4 files +28/-18. NO Linear ticket on this one; titled without a DEV- prefix. Verified isolated: 6209 contains the MAX_BY expression and does NOT contain northpond_balancesheet. 171 northpond tests pass.
This is the one that must land before the first live EDGEX purchase file on 2026-08-11.
- 2026-08-10T19:00Z [claude-code] CODE-REVIEW FINDING CONFIRMED + FIXED 2026-08-11. A review agent flagged that the FUND_WITH_PURCHASE_TAPE_EXPR change left stale documentation behind. VERIFIED REAL: NorthpondStmtPositions.generate_sql and NorthpondStmtTransactions.generate_sql both carried the identical docstring paragraph 'FUND is set via a correlated IN subquery ... : efhyf if the loan appears in silver.northpond_stmt_purchase_tapes on or before AS_OF_DATE' — wrong on both counts after the change (it is a correlated SCALAR subquery, and it returns the fund from the tape row, not efhyf).

Two precisions on the report: they are generate_sql METHOD docstrings (stmt_positions.py:171-175, stmt_transactions.py:58-62), not module docstrings; and the module docstrings never mentioned the fund logic at all. Impact assessment in the report was right — documentation only, zero runtime effect.

FIXED in commit e0b4a20ce on abhishek/northpond-purchase-tape-fund-from-tape-row (PR #6209), pushed. Both docstrings now read 'correlated scalar subquery ... the fund recorded on the loan latest silver.northpond_stmt_purchase_tapes row on or before AS_OF_DATE'. Verified: git grep 'correlated IN subquery' returns nothing on the branch; ruff format + check clean; 171 northpond tests pass.

LESSON WORTH KEEPING: the constants.py comment was updated in the original commit but the two CONSUMER docstrings that paraphrase the same expression were not. When changing a shared SQL expression in northpond/constants.py, grep the importers for prose describing it, not just the symbol.
- 2026-08-10T19:41Z [claude-code] EDGEX FUND PRECEDENT ACROSS PLATFORMS (Snowflake, read-only, 2026-08-11) — this explains WHY the northpond ACCOUNT_NAME gap exists and what the fix should look like.

EVERY OTHER PLATFORM SEPARATES EDGEX AT THE ACCOUNT/FEED LEVEL, NOT VIA THE PURCHASE TAPE. Statements arrive under a dedicated per-deal account name and FUND is a straight ACCOUNT_NAME -> fund mapping. Upgrade is the clearest: bronze ACCOUNT_NAMEs are EdgeFocusEDGEX20251NN_9268450, EdgeFocusEDGEX20252NN_9326818, EdgeFocusEDGEX2026PT1_9357538, EdgeFocusEDGEX2026PT2_9372898, EdgeFocusEDGEXPurchaserI_9266405, EdgeFocusEDGEXPurchaserII_9356514 — each carrying its own positions/transactions/purchase_tape/final_purchase/final_sale streams. silver ACCOUNT_ID is the numeric suffix. marlette uses small numeric account ids (547, 530, 193, 183, 184, 181), prosper numeric (14923933, 15307393, 15983181), happymoney numeric (62, 64).

NORTHPOND IS THE ODD ONE OUT: all Oliv statements arrive under the single account ef_northpond, and the fund is INFERRED from the purchase tape (FUND_WITH_PURCHASE_TAPE_EXPR). That is why NORTHPOND_ACCOUNT_FUND_MAP's INV103/INV105 entries have nothing to populate them — no feed ever carries those account names. Confirmed in data: ZERO silver.positions rows have ACCOUNT_ID containing INV103 or INV105, and FUND='edgex_purchaser' has NEVER been written anywhere (0 rows in positions.fund and transfers.to_fund).

edgex20261NN IS ALREADY LIVE — but on PROSPER, not northpond: account_id 15983181, 19 loans, 2026-08-06 -> 2026-08-09. So the 2026-1NN deal is flowing for other platforms already; northpond has 0.

NOTE ON EDGEX PURCHASER I: on upgrade it is a STAGING account — EdgeFocusEDGEXPurchaserI_9266405 carries purchase_tape/pending_purchase/final_purchase/final_sale, and its positions rows map to fund edgex20251NN (2178 loans, ended 2025-07-02). So Purchaser I is a waypoint, not a terminal fund. That is consistent with Nate saying INV105 is 'the exception' and everything sits in INV103 ([[wm-5z3pjt]]).

IMPLICATION FOR THE FIX: the precedent says EDGEX separation should come from the FEED. Nate already said (2026-07-28) the Nelnet loan file will carry the investor tag — that is the account-level mechanism other platforms use. Until either that lands or the v0 purchase tape carries an investor id that the parsing rule turns into account_name, PR #6209 alone cannot produce a non-efhyf fund for northpond.
- 2026-08-11T20:58Z [claude-code] DATE-BASED FUND SPLIT IMPLEMENTED 2026-08-12, per Abhishek's decision after discussing with Nate. This SUPERSEDES the MAX_BY approach in PR #6209.

WHY THE APPROACH CHANGED: #6209 derives fund from the purchase-tape row's FUND, which comes from ACCOUNT_NAME. Nothing populates ACCOUNT_NAME with INV103 (the v0 parsing rule hardcodes northpond_efhyf), so #6209 alone can never yield edgex20261NN. The date rule needs no ACCOUNT_NAME and works today.

RULE: purchase tape, purchase_date >= 2026-08-01 -> edgex20261NN; purchase_date < 2026-08-01 -> efhyf; absent from the purchase tape -> account->fund map (experimental, becoming northpond_balancesheet via [[wm-qtjmcv]]). Third leg is unchanged behaviour.

COMMIT 4bdabd8be on abhishek/northpond-edgex-fund-date, isolated worktree ~/claude-ws/oliv-fund-date/efp off origin/master c11d1fa84. 2 files, +36/-12. NOT PUSHED, NO PR YET - pending Abhishek's call on whether to retarget PR #6209 (open, base master, CONFLICTING, no human review, only a sentry bot comment) or raise a new one.

New constant NORTHPOND_EDGEX_PURCHASE_START = 2026-08-01. FUND_WITH_PURCHASE_TAPE_EXPR is now a CASE with two correlated IN subqueries, both still scoped TRY_TO_DATE(PURCHASE_DATE) <= src.AS_OF_DATE; EDGEX arm first so a resold loan follows its later purchase. 175/175 northpond tests pass (170 existing + 5 new); every pre-existing assertion still holds, so the SQL shape stayed compatible.

VALIDATED AGAINST THE INVESTOR TAG - the strong evidence for the 2026-08-01 boundary. The Nelnet loan file carries an investor code at pipe-field 39 (INV103 / blank); it is the only place INV103 appears in any data we receive. Checked the 160 loans across the 11 purchase files now in S3: the date rule reproduces the Nelnet tag 160/160, zero disagreements (35 blank -> efhyf, 125 INV103 -> edgex20261NN). Last pre-cutover purchase_date 2026-07-31, first post-cutover 2026-08-03, so the boundary sits in a clean 3-day gap. NOTE: the 2026-07-28 date on the unmerged dev-1474 branch scores only 129/160 - it would put 31 blank-investor July loans into EDGEX.

NO-OP ON CURRENT DATA: old vs new expression replayed side by side over the latest prod loan tape gives identical funds (372 efhyf, 343 experimental, 0 rows differing). All 372 tape purchases are 2025-02-05..2025-06-17, so the EDGEX arm stays dormant until live purchase files land.

LIMITATION, stated in the code comment: purchase date cannot separate INV105 (EDGEX Purchaser I) from INV103 (EDGEX Grantor Trust); every post-cutover purchase reports edgex20261NN. Parsing the Nelnet investor tag remains the real fix. ACCOUNT_ID needs no code change - NORTHPOND_FUND_ACCOUNT_MAP already inverts edgex20261NN to INV103, so positions.ACCOUNT_ID follows the fund.
- 2026-08-12T13:09Z [claude-code] Now live, not hypothetical: real v0 purchase-file rows landed 2026-08-11 (29 rows) and FUND_WITH_PURCHASE_TAPE_EXPR stamped them efhyf. Today that is still correct (ACCOUNT_NAME=northpond_efhyf), but the expression ignores ACCOUNT_NAME entirely — any loan appearing in silver.northpond_stmt_purchase_tapes with PURCHASE_DATE <= AS_OF_DATE becomes efhyf. The moment Oliv delivers a purchase file under INV103/INV105, positions+transactions will be mislabeled efhyf instead of edgex_2026_1 / edgex_purchaser.
- 2026-08-12T13:28Z [claude-code] MERGED + DEPLOYED 2026-08-11, but PROD STILL HOLDS THE STALE FUND (verified 2026-08-12). PR #6209 'Fix northpond purchase-tape fund by splitting it on purchase date at the EDGEX cutover' merged 2026-08-11T21:48Z as 804310be3 — i.e. the date-based split from the previous entry was retargeted onto #6209 and shipped, not left unpushed. origin/master carries NORTHPOND_EDGEX_PURCHASE_START='2026-08-01' at northpond/constants.py:21. The correction to the entry above: #6209 is not 'open, CONFLICTING' any more.

WHAT PROD ACTUALLY SHOWS NOW: PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES holds 29 rows at AS_OF_DATE=2026-08-11 with PURCHASE_DATE=2026-08-11, ACCOUNT_NAME=northpond_efhyf and FUND='efhyf'. Under the merged rule those purchase dates are >= 2026-08-01 and must resolve to edgex20261NN. The rows are stale because they were written on 08-11 BEFORE the deploy, and the purchase tape has not been rebuilt since (MAX(AS_OF_DATE)=2026-08-11, 401 rows total). So the stored FUND on the tape is wrong today.

WHY THIS STILL BITES even though positions look fine: none of the 29 loan ids (OLV12563552, OLV12563575, OLV12563554, ...) appear in SILVER.NORTHPOND_STMT_POSITIONS at any as_of yet — 0 matched — which is expected, since Nate said 2026-08-12 'there can be a few day delay to get into the NN file but once there it is always there'. When they DO arrive, positions will evaluate the new expression and get edgex20261NN, while transfers.TO_FUND reads the tape's stored FUND and gets efhyf. That is the positions-vs-transfers disagreement this item exists to prevent, arriving a few days late. Rebuilding the purchase tape before the loans land in the loan tape avoids it entirely.

Code work is done and merged, so closing; the rebuild is tracked separately.
