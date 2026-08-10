---
id: wm-qtjmcv
type: task
title: DEV-1509: rename the northpond 'experimental' fund to northpond_balancesheet
status: open
priority: p3
size: s
people: [Sean]
tags: [northpond]
links: [relates:wm-7qqeke]
refs: [DEV-1509=https://linear.app/edge-focus/issue/DEV-1509/rename-experimental-northpond-fund]
created: 2026-08-10T14:53:27Z
updated: 2026-08-10T15:35:58Z
source: claude-code
---

## Log
- 2026-08-10T14:53Z [claude-code] Filed by Sean Mills 2026-08-05, moved Backlog -> Todo 2026-08-10 14:49Z, assigned Abhishek, No priority, no due date. Ticket text: 'This should probably say northpond_balancesheet or something for clarity. Also, should confirm these are showing up where relevant such as MOB curves.'

RELATED TO BUT NOT THE SAME AS [[wm-7qqeke]] (the FUND_WITH_PURCHASE_TAPE_EXPR hardcoded-efhyf fix). Same file and adjacent lines — FUNDS.EXPERIMENTAL is NORTHPOND_ACCOUNT_FUND_MAP['ef_northpond'] at northpond/constants.py:16, the efhyf hardcode is at :50 — so the two will conflict textually if done in parallel, but they are independent fixes. wm-7qqeke is Tuesday-blocking (first live EDGEX purchase file 2026-08-11); DEV-1509 is not.

BLAST RADIUS (verified on origin/master d1e9c461c): FUNDS.EXPERIMENTAL is northpond-only — just 3 references, all in northpond files (northpond/constants.py:16, northpond/transfers.py:143 TAPE_FROM_FUND, northpond/transfers.py:184 TAPE_FUND). The enum member itself sits in the SHARED edgefocus/transformations/silver/statement_rows/constants.py:41, but no other platform consumes it, so the shared-file edit is a single enum value with no cross-platform reach.

THE REAL COST IS DATA, NOT CODE — the literal string 'experimental' is already persisted in prod (2026-08-10): silver.northpond_stmt_positions 155,812 rows; silver.northpond_stmt_transactions 38,878 rows; silver.positions (platform=northpond) 155,823 rows. ~350k rows total. Changing the enum VALUE only affects rows written after the change, so without a backfill the same fund exists under two names and every downstream group-by splits. Sean's 'confirm these are showing up where relevant such as MOB curves' is exactly that concern. Decide up front: rename value + backfill existing rows, or keep the stored value and rename only the display.

NOTE the efhyf side is unaffected by this ticket: silver.northpond_stmt_positions has 179,093 efhyf rows and northpond_stmt_transactions 102,939.
- 2026-08-10T15:35Z [claude-code] IMPLEMENTED + PR RAISED 2026-08-10: https://github.com/edgefocus/efp/pull/6208 (open, base master, head abhishek/dev-1509-rename-experimental-northpond-fund, 20 files, +68/-53). Two commits: 7aa88bd78 (the [[wm-7qqeke]] efhyf fix) and 9e6087b51 (this rename). Abhishek chose to carry both in one PR since they touch adjacent lines of northpond/constants.py, and said the Linear ticket may not be updated.

RENAME SCOPE AS SHIPPED: FUNDS.EXPERIMENTAL -> FUNDS.NORTHPOND_BALANCESHEET with value 'experimental' -> 'northpond_balancesheet' (statement_rows/constants.py:41). Symbol refs updated in northpond/constants.py, northpond/transfers.py (x2), transfers_test.py. HARDCODED LITERALS that a symbol rename would have missed, all fixed: lib/efp/stats/portfolio_views.py FUNDS_EXCLUDED_FROM_ALL + the 3 'Experimental Funds*' view filters (incl. both Mob Curves views — Sean's concern); lib/efp/stats/edgex/constants.py INVALID_FUNDS; configs/default_passwords.json funds key (feeds datastore_accounts.py -> datastore 'fund' column); northpond_constants_test.py and positions_test.py assertions. Also 5 terraform column comments and the prose in positions.py, northpond_api_predictions*.py, northpond_assets.py, datastore_stand_pos_first_pass_northpond.py, positions_snowflake_map.py. VIEW NAMES deliberately NOT renamed — only the values they filter on.

SHARED-FILE EXCEPTION: lib/efp/stats/portfolio_views.py and lib/efp/stats/edgex/constants.py are shared/legacy files normally off-limits. Flagged to Abhishek before editing and he approved, because a rename that skips them is actively broken (three views would empty and the fund would leak into every aggregate view). Called out explicitly in the PR body rather than slipped in.

VERIFIED: ruff format + ruff check + mypy clean; 3551 edgefocus tests, 105 orchestration tests, 209 northpond+predictions tests pass. lib/ shows 127 collection errors (missing termcolor etc. in the uv venv) — IDENTICAL count on clean master with changes stashed, so pre-existing, not introduced. Snowflake proof for the efhyf half: 715 loans, 0 mismatches, 0 NULL.

DEPLOYMENT STILL OWED — the rename does NOT migrate existing rows by itself. Abhishek's read (verified correct): silver is written by snowflake.delete_and_insert per as_of_date, NOT a conditional MERGE, so a full as_of_date backfill of northpond_stmt_positions, northpond_stmt_transactions and positions rewrites every row onto the new fund name. Until that backfill runs, prod holds both values: 155,812 / 38,878 / 155,823 rows respectively still say 'experimental'.

WORKSPACE: ~/claude-ws/dev-1509/efp on dpx (own clone off origin/master d1e9c461c, own uv venv). No ~/repos* checkout was modified.
