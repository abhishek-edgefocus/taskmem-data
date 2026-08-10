---
id: wm-7qqeke
type: task
title: Fix northpond FUND_WITH_PURCHASE_TAPE_EXPR hardcoded efhyf before Oliv EDGEX purchase files land
status: next
priority: p1
size: s
due: 2026-08-11
people: [Abhijeet]
tags: [northpond, edgex]
links: [relates:wm-5z3pjt, parent:wm-j523sq]
created: 2026-07-31T17:01:37Z
updated: 2026-08-10T19:00:18Z
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
