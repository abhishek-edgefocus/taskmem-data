---
id: wm-qtjmcv
type: task
title: DEV-1509: rename the northpond 'experimental' fund to northpond_balancesheet
status: active
priority: p3
size: s
people: [Sean]
tags: [northpond]
links: [relates:wm-7qqeke]
refs: [DEV-1509=https://linear.app/edge-focus/issue/DEV-1509/rename-experimental-northpond-fund, PR-6208=https://github.com/edgefocus/efp/pull/6208]
created: 2026-08-10T14:53:27Z
updated: 2026-08-12T13:28:27Z
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
- 2026-08-10T15:52Z [claude-code] PR SPLIT 2026-08-10. #6208 now carries ONLY the DEV-1509 rename (20 files, +42/-37); the efhyf fix moved to #6209 ([[wm-7qqeke]]). Branch force-pushed with --force-with-lease pinned to the inspected tip 9e6087b512da01ccc4fb5c65a9749cc8cf8628fc (verified beforehand that the remote held only my two commits). Verified isolated: 6208 has northpond_balancesheet and does NOT have MAX_BY.
TERRAFORM COMMENT SPLIT: silver_northpond_stmt_positions.tf and silver_northpond_stmt_transactions.tf each have one column comment describing BOTH the fund name and the purchase-tape behaviour. Each PR now changes only its own half — 6208 renames the fund in the comment and keeps master's 'efhyf when loan appears on purchase tape' wording; 6209 changes the behaviour wording and keeps 'experimental'. EXPECT A TRIVIAL CONFLICT on those two lines when the second PR merges; resolve to 'Fund: taken from the purchase tape when the loan appears on it as of AS_OF_DATE, else northpond_balancesheet'.
MERGE ORDER: 6209 first (deadline-driven), then rebase 6208.
PR bodies have no screenshots — the Snowflake proof is inline as markdown tables. Per the PR style guide the real screenshots (SQL + result in frame) still need pasting before review.
- 2026-08-10T19:29Z [claude-code] SNOWFLAKE RECON 2026-08-11 (read-only) on fund naming across platforms, prompted by Abhishek asking what other platforms populate.

NO 'AJAX' ANYWHERE: searched silver.positions (PLATFORM, FUND, ACCOUNT_ID, CHANNEL), silver.transfers (TO_FUND, FROM_FUND) and bronze.statement_rows (PLATFORM, ACCOUNT_NAME) across ALL history — zero rows. Either it is not in prod yet or the term means something else; asked Abhishek.

'experimental' IS NORTHPOND-ONLY, CONFIRMED IN DATA: 155,823 rows in silver.positions, 2024-07-10 -> 2026-08-10, PLATFORM='northpond' exclusively. No other platform has ever written it. This corroborates the earlier code-level finding (FUNDS.EXPERIMENTAL had only 3 references, all northpond) and means the DEV-1509 rename cannot affect another platform.

10 PLATFORMS in silver.positions: anchored, happymoney, lc, marlette, northpond, openroad, prosper, sofi, upgrade, upstart.

FUND NAMING SPLITS INTO TWO CAMPS. Cross-platform vehicles: efhyf (8 platforms), edgex2026PT1/PT2 (4), paradigm1 (4), edgex20251NN/20252NN (3), efalpha (3), macq_wh (3), macq_wh2 (3), edgex20261NN (1, prosper only so far). Platform-specific: fortress_happymoney, fortress_marlette_hyp, fortress_marlette_hyp_2, fortress_prosper, fortress_sofi, castlelake_auto, lcbs, nb, sp, spc2, experimental.

*** NAMING PRECEDENT WORTH RAISING ON PR #6208 ***: the direct analogue to northpond's balance-sheet fund already exists — 'lcbs' (LendingClub balance sheet), lc-only, 1,506 loans on the latest tape. House style for a platform's own balance-sheet fund is the short <platform>bs form, so the precedent name would be 'npbs', not 'northpond_balancesheet'. Sean's ticket proposed 'northpond_balancesheet ... or something', so this is open. Existing platform-specific funds are otherwise <owner>_<platform> (fortress_*) or short codes; <platform>_<purpose> would be a new shape. Flagged to Abhishek — decide before #6208 merges, since changing it afterwards means a second rename plus a second backfill.
- 2026-08-11T19:02Z [claude-code] CI FAILURE ON #6208 — REAL, MY MISS, NOW FIXED (2026-08-11). northpond_transfers.md::test_snowflake failed: expected FROM_FUND='experimental', got 'northpond_balancesheet'.

ROOT CAUSE OF THE MISS: my original sweep piped grep through 'head -30' and silently truncated. FIVE files were never updated. A full 'git grep' (tracked files, no truncation) found them: integration_tests/md_tests/northpond_transfers.md (13 occurrences — expected FROM_FUND/TO_FUND cells, the composite POOL_IDs, and the prose), northpond/transfers.py (8, module docstring + inline comments), northpond/transfers_test.py (3, incl. test_to_fund_is_experimental), silver/comparison/northpond_verified.py (1), docs/northpond/snowflake-datastore-comparison.md (2). 27 occurrences total, fixed in commit 6fbae966a, pushed.
LESSON: never truncate a completeness sweep with head/tail. Also note \\bexperimental\\b would NOT have worked — '_' is a word character, so it skips northpond_experimental in the POOL_IDs.

*** NEW FINDING — POOL_ID EMBEDS THE FUND NAME ***: silver.transfers.POOL_ID is a composite {date}_{platform}_{fund} (and {date}_{platform}_{from}_{to}), e.g. 20250617_northpond_experimental_efhyf. After the rename it becomes 20250601_northpond_northpond_balancesheet — the platform name repeats. Raised the option of 'npbs' instead (matching the existing lcbs = LendingClub balance sheet precedent, which would give 20250601_northpond_npbs); ABHISHEK DECIDED 2026-08-11 to keep northpond_balancesheet. Decision made with the POOL_ID consequence known — do not re-litigate.

BACKFILL SCOPE IS WIDER THAN THE PR BODY STATES: silver.transfers northpond rows also change — 777 rows with POOL_ID ilike '%experimental%', 715 with TO_FUND='experimental', 372 with FROM_FUND='experimental' (out of 1,087 total northpond transfers). These are ON TOP OF the 155,812 / 38,878 / 155,823 position+transaction rows. The PR's Deployment section still only lists the latter three — needs updating before merge.

OPENROAD FIXTURE LEFT ALONE DELIBERATELY: integration_tests/md_tests/openroad_positions.md uses 'experimental' as arbitrary fixture data for another platform (lines 21, 78, 79, 92). Its assertions are self-consistent and its test passes, and touching another platform's fixtures is outside this ticket. Worth a follow-up sometime since it now references a fund value that no longer exists in FUNDS.

ALSO: an AI review agent flagged #6208 for 'omitting' the FUND_WITH_PURCHASE_TAPE_EXPR change. NOT VALID — that change is deliberately in #6209 per the agreed split, and the location it cited (constants.py L9-L19) is NORTHPOND_ACCOUNT_FUND_MAP, not the expression (L39-53). No action taken.
- 2026-08-12T13:28Z [claude-code] MERGED + DEPLOYED, and the backfill gap is now REAL IN PROD (verified 2026-08-12 18:5x IST). PR #6208 merged 2026-08-11T19:50Z as 42db18e68. Prod is running the new code: silver.northpond_stmt_positions AS_OF_DATE=2026-08-12 writes FUND='northpond_balancesheet' (343 rows), while 2026-08-11 and every earlier date still say 'experimental'. Counted in PROD: experimental 156,155 rows (latest as_of 2026-08-11), northpond_balancesheet 343 rows (latest as_of 2026-08-12). This is exactly the split-fund state this item warned about — one fund now exists under two names and every downstream group-by splits. The as_of_date backfill of northpond_stmt_positions, northpond_stmt_transactions, silver.positions AND silver.transfers (777 POOL_ID / 715 TO_FUND / 372 FROM_FUND rows) has NOT run. Code work is complete, so closing this; the backfill is tracked separately.
