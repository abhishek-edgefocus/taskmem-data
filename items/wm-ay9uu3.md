---
id: wm-ay9uu3
type: task
title: Map FULLY_PAID_DATE for OpenRoad (DEV-1539)
status: next
size: s
people: [Abhijeet]
tags: [openroad, platform-data-owners]
links: [relates:wm-cgftbn, parent:wm-su6q4d, relates:wm-j5p44v, blocked-by:wm-j5p44v]
refs: [DEV-1539=https://linear.app/edge-focus/issue/DEV-1539/add-fully-paid-date-mapping-for-openroad]
created: 2026-08-12T13:30:20Z
updated: 2026-08-21T20:51:32Z
source: claude-code
label: OpenRoad fully-paid date
---

Abhijeet split the FULLY_PAID_DATE mapping ask into one ticket per platform on 2026-08-11 19:22Z and assigned the OpenRoad one to Abhishek (DEV-1539, Backlog, no priority, no due date). The siblings went elsewhere: DEV-1516 NorthPond (Abhishek, tracked as [[wm-cgftbn]]), DEV-1538 Upstart and DEV-1540 LendingClub (both Kushagra). So this is the OpenRoad twin of work already scoped in detail on [[wm-cgftbn]].

Nearly all the analysis carries over — read [[wm-cgftbn]] first. The shared facts: the column exists only as a ColumnDefinition in `positions_constants.py:899` and `terraform/snowflake/silver_positions.tf:832`, no platform has mapped it yet, and the semantic to match is the legacy `datastore_closed_positions.py:70` one — `fully_paid_date` = the as_of_date on which STATUS first became `fully_paid`. The Prosper `RESOLVED_CHARGE_OFF_DATE` pattern (`prosper/positions.py:260-266`) is the precedent: compute the window in a subquery over the UN-date-filtered `silver.openroad_stmt_positions`, because a naive window inside COLUMN_MAPPING only sees the processing window and returns today's date on incremental runs.

What is genuinely OpenRoad-specific and not yet known: whether the OpenRoad tape carries a payoff-date field at all, or whether the date has to be derived from the status history the way NorthPond's does.

Caveat before starting: the OpenRoad silver chain has not run since 2026-07-07 ([[wm-85nuv4]]), so any prod sizing or validation baseline taken from `silver.openroad_stmt_positions` today is five weeks stale. Fix or account for that first, or the numbers will mislead.

## Next steps
1. Flatten RAW_RECORD keys on recent OpenRoad bronze positions rows and check for any payoff/paid-off date field before assuming it must be derived.
2. Read [[wm-cgftbn]]'s implementation notes and mirror them in `edgefocus/transformations/silver/statement_rows/openroad/positions.py`.
3. Count `fully_paid` OpenRoad loans in prod for a validation baseline — but see the staleness caveat above.
4. Decide whether to do this jointly with DEV-1516 in one PR, since the two mappings are near-identical.

## Links
- DEV-1539 — https://linear.app/edge-focus/issue/DEV-1539/add-fully-paid-date-mapping-for-openroad
- DEV-1516 (NorthPond twin) — https://linear.app/edge-focus/issue/DEV-1516/add-fully-paid-date-mapping-for-northpond
- Origin PR #6008 (added the column) — https://github.com/edgefocus/efp/pull/6008

## Log
- 2026-08-20T10:58Z [claude-code] DEV-1516 (the NorthPond twin) is implemented — see wm-cgftbn. Two findings carry over to OpenRoad:

1. Do NOT assume the LAG/LAST_VALUE current-run pattern is right. It is what prosper/anchored/sofi/marlette/figure use, but NorthPond needed MIN because its tape flaps in and out of the paid-off status with the balance already at zero. Check OpenRoad's tape for the same flapping before choosing: count loans with more than one not-paid -> paid transition, and look at whether the balance is already 0 at the first one.

2. The legacy closed_positions datastore is not a trustworthy oracle for this column. It stamps one row per transition and consumers keep the LAST, which produced dates months after the real payoff for NorthPond. Compare against its FIRST row per efp_id, not its last.

The NorthPond implementation is a LEFT JOIN subquery over the un-date-filtered positions source, gated in COLUMN_MAPPING on the row's own mapped status — copyable shape for openroad/positions.py.
- 2026-08-20T19:40Z [claude-code] Implemented on branch abhishek/dev-1539-fully-paid-date in ~/claude-ws/dev-1539/efp (commit b8ba70536, NOT pushed — waiting on his call). PR body drafted at ~/claude-ws/dev-1539/notes/PR_BODY.md.

Both open questions from the scoping notes are now answered, and one of the two answers changed the design.

1. The OpenRoad tape carries NO payoff-date field. Listed all 65 columns of silver.openroad_stmt_positions and flattened every RAW_RECORD key on the 2026-08-18 rows (51 keys): nothing payoff/paid-off shaped. So the date has to be derived, same as NorthPond.

2. The tape does NOT flap — 14 loans enter fully_paid, 0 ever exit, across all 51 days on file. So the NorthPond flapping rationale does not apply here, though MIN is still the right choice: OpenRoad's STATUS is derived from balances (generate_derived_status: ORIGINATION_PRINCIPAL - TOTAL_PRINCIPAL_PAID < 1), not from a servicer status column, so a payment reversal is the realistic flap risk and MIN keeps the true payoff if one ever lands.

THE FINDING THAT CHANGED THE DESIGN — left-censoring, which no other platform has:
The OpenRoad loan tape starts 2026-06-29 while the book goes back to 2023. All 35 loans are already on file on that first date, and 13 of the 14 that read fully_paid had paid off months to years earlier (2024-09 through 2026-04). A pure status-transition derivation — what every other platform does — would stamp all 13 with 2026-06-29, wrong by up to 22 months.

So the mapping has two branches. Transition observed on the tape -> the transition AS_OF_DATE (the column's stated semantic). Already fully_paid on the loan's first tape row -> the LAST_PAYMENT_EFFECTIVE_DATE it carried there, i.e. the payment that closed it. That field is stable and non-null: 14/14 paid-off loans have exactly 1 distinct value.

CORRECTION to the earlier note on this item, which said the legacy closed_positions datastore is not a trustworthy oracle. That was true for NorthPond and is NOT true for OpenRoad. The OpenRoad legacy datastore (s3://efp-derived/datastores/openroad/closed_positions/v1902/) holds one row per loan, not one per transition, and 13/14 of its dates match this implementation exactly. It is a usable oracle here.

The single disagreement, 4923612: legacy 2025-05-27 vs ours 2025-04-22 (-35d). It is a legacy observation lag, not a disagreement about the loan — legacy stamped it the same day it also closed 5865766, while the tape puts 4923612's final payment on 2025-04-22 and the balance has not moved since. Our value is arguably the more accurate one. If reviewers want exact legacy parity this is the one row that has to move, and it belongs in the openroad verified-differences set (see [[wm-skvqac]]).

The load-bearing validation row is 4976517 — the ONLY OpenRoad loan whose transition we actually observe. Legacy says 2026-07-20, we say 2026-07-20. Its final payment landed 2026-07-17, three days earlier, so this also confirms the date follows STATUS rather than the payment, as the column specifies.

Validation: Dagster-materialized openroad_positions into DEV_ABHISHEK for 2026-07-20 (run 76a1e751-a407-40b9-99c2-87d19a1279b6, RUN_SUCCESS, 35 deleted / 35 inserted). Picked that date because it is the one date on which a loan transitions, so both branches are exercised. On the rebuilt date 14/14 fully_paid rows dated, 0 leaked onto non-fully-paid rows, 0 in the future; untouched 2026-07-19 and 07-21..23 still read 0 dated, a clean before/after inside one table; 0 loans differ from the untouched neighbour on any of 10 other columns. 1388 tests pass, ruff + mypy clean.

Tests: 6 behavioural tests (TestFullyPaidDate) that execute the real join + mapping SQL through duckdb rather than asserting on SQL substrings. Mutation-checked 4 ways — MIN->MAX (4 fail), gate removed (3), censoring branch removed (2), transition branch removed (3).

Two gotchas for the next OpenRoad workspace: my workspace has no .venv, so ~/repos/efp/.venv/bin/python works but ONLY with PYTHONPATH=<ws>/efp:<ws>/efp/lib; and the snowflake session helper reads .env from cwd, so copy ~/repos/efp/.env into the workspace and set SNOWFLAKE_DATABASE explicitly.

Also worth knowing: the earlier staleness caveat on this item is stale itself. silver.openroad_stmt_positions is current to 2026-08-18 — it is silver.positions that is stuck at 2026-07-06 ([[wm-85nuv4]]). The tape was fine to size from.
- 2026-08-20T19:47Z [claude-code] PR raised as DRAFT: https://github.com/edgefocus/efp/pull/6413 (branch abhishek/dev-1539-fully-paid-date, +198/-1, 2 files) at his explicit instruction. Body is ~/claude-ws/dev-1539/notes/PR_BODY.md on dpx; validation SQL at ~/claude-ws/dev-1539/notes/verify_dev.sql, legacy comparison script at notes/compare_legacy.py, mutation harness at notes/mutate.sh.

Open loose ends before it leaves draft:
1. No screenshots attached — the body carries the numbers as markdown tables. Needs the DEV_ABHISHEK Snowflake shots (query + result in frame) for the before/after table and the per-loan date table.
2. The 4923612 legacy difference (-35d) is flagged in the body but not yet registered anywhere. Decide with the reviewer whether to match legacy exactly or register it as a verified difference in the openroad set ([[wm-skvqac]]).

DAG is genuinely unchanged — no new asset and no new source table; _FULLY_PAID_DATE_JOIN reads silver.openroad_stmt_positions, already a StreamSource of openroad_positions. So the DAG section is the literal 'unchanged' line, not a missing screenshot.
- 2026-08-20T20:48Z [claude-code] 2026-08-21: PR #6413 opened as a DRAFT (DEV-1539: Map FULLY_PAID_DATE for OpenRoad). Branch abhishek/dev-1539-fully-paid-date, commit b8ba70536. The session surveyed all seven platforms mapping this column: six (prosper, anchored, sofi, marlette, figure) use a LAG/LAST_VALUE 'current fully-paid run' pattern; innovate and NorthPond #6401 use MIN; OpenRoad needed a departure from both. Kept in draft per the draft-until-ready rule.
- 2026-08-20T20:51Z [claude-code] Verified on a Dagster server running from my own workspace, at his request.

Server: http://dexterplus.edgefocus.net:13080, serving ~/claude-ws/dev-1539/efp (the branch code) with DAGSTER_HOME=~/claude-ws/dev-1539/dagster_home. Took 13080 because 13054 (repos-2), 13077 (oliv-exp), 13078 (openroad-gold) and 13079 (dev-1516) are other sessions' — all four confirmed still listening afterwards, nothing disturbed.

Gotcha: ~/repos/efp/.venv has NO dagster-webserver (only dagster + dagster-daemon), and uv is not on the non-interactive PATH. Start it with ~/.local/bin/uv run --extra orchestration from the workspace, which builds the workspace's own .venv. Takes ~4 min the first time.

Two independent forced rebuilds, both RUN_SUCCESS, 35 deleted / 35 inserted each:
- 76a1e751-a407-40b9-99c2-87d19a1279b6 -> 2026-07-20 (the one date a loan transitions, so both branches fire)
- a88bf9a5-cab3-4ce3-bd25-a9782f004d1b -> 2026-07-22 (second, independent)
Both serve HTTP 200 at :13080/runs/<id>.

DEV_ABHISHEK verification, all 25 OpenRoad dates:
- Only the 2 rebuilt dates carry FULLY_PAID_DATE (14/14 each). The other 23 read 0 — untouched controls in the same table.
- 0 leaked onto non-fully_paid rows, 0 in the future, 0 before origination, on EVERY date.
- The two rebuilds agree loan-for-loan: 0 rows differ between 07-20 and 07-22. This rules out a run-order/watermark artifact, which the single-run evidence could not.
- Recomputing the expected date straight from silver.openroad_stmt_positions, independently of the transform: 0 disagreements.
- Cross-platform: of the 8 platforms in DEV_ABHISHEK.SILVER.POSITIONS only openroad (28 = 14 x 2) and northpond (76, from wm-cgftbn's own run) carry any date. Nothing else moved.
- Branch split holds: 13 closing-payment (2024-09-04..2026-04-24), 1 transition (2026-07-20).

PR #6413 body updated with the second run, the run URLs and the three zero-row assertions. The old body claimed 2026-07-22 read 0 dated, which the second rebuild made false — that table is corrected, not just extended.

CI footnote: the first 'Run Tests' failure was the self-hosted runner losing communication, not the change. PyTest never executed. Re-ran the same commit untouched: all 4 checks green.
- 2026-08-21T17:31Z [claude-code] 2026-08-21 23:00 IST: DEV-1539 is DUE TODAY (Linear dueDate 2026-08-21, status still Todo). PR #6413 is green but still draft; its session was BLOCKED on a permission prompt mid-validation. Abhishek's stated priority order tonight: 1) reply to Scott's PR review question, 2) DEV-1539, 3) enable openroad_statement_sensor, 4) NorthPond Experian credit-pull failures (DEV-1478).
- 2026-08-21T17:33Z [claude-code] 2026-08-21 read-only investigation: the 13 censored payoffs do not need seeding OR the closing-payment fallback. The pre-tape history is NOT missing — 1,127 daily LoanTape files sit in s3://efp-raw/statements/openroad/ back to 2023-07-20, unbroken; bronze holds only 52 of them because the openroad_loan_tape parsing rule merged 2026-06-29 (PR #5640) and the one-off S3 backfill was never run. openroad_stmt_positions needs none of the columns added after 2023-09 and FUND is a constant, so the whole series parses with zero code change. Once loaded, generate_derived_status observes each payoff on the day the balance goes to zero. See [[wm-j5p44v]]. Recommend holding PR #6413 until after the backfill.
- 2026-08-21T17:49Z [claude-code] Seed work STOPPED and reverted on his instruction. A parallel session (wm-j5p44v) found the premise was wrong: there is no OpenRoad history gap. s3://efp-raw holds all 1,127 daily loan-tape files back to 2023-07-20 with zero missing days; PROD bronze holds only 52 because 2026-06-29 is the merge date of PR #5640's openroad_loan_tape parsing rule, and the one-off S3 backfill was never run. The sibling purchase tape on the same platform WAS backfilled, and anchored (same file family) was backfilled in #5428/#5576.

So the left-censoring problem I designed around was self-inflicted — it was missing bronze data, not missing source data. Both of my attempted fixes (the LAST_PAYMENT_EFFECTIVE_DATE inference, then the 13-loan verified seed) were working around a gap inside the transform. Both are removed.

Branch abhishek/dev-1539-fully-paid-date is now the plain derivation and nothing else: MIN(AS_OF_DATE where derived status = fully_paid) over the un-date-filtered silver.openroad_stmt_positions, gated in COLUMN_MAPPING on the row's own status. Same shape as innovate. +33 in positions.py, +139 in tests. Commit 8fbf6ad6c, force-pushed.

Tests cut from 10 to 5, all behavioural (real join + mapping SQL through duckdb): transition dating + carry-forward, row-level gate, whole-history-not-processing-window, MIN on flip-back, per-loan. 73 openroad tests pass; 4038 pass across edgefocus; ruff/mypy clean; dagster definitions validate.

PR #6413 retitled "(blocked on bronze loan-tape backfill)", body rewritten with an IMPORTANT callout, the raw-vs-bronze coverage table, and the three things needed before it leaves draft: backfill runs, re-validate in DEV against the restored tape with screenshots, re-run the legacy comparison over the full history. Kept as draft, branch NOT deleted.

Note the DEV_ABHISHEK openroad rows are currently stale/mixed: 2026-07-20 was rebuilt with the seeded logic (14/14 matching ground truth) and 2026-07-22 still carries the older last-payment logic. Neither reflects the branch as it now stands. Do not read DEV as evidence for this PR until it is rebuilt over the backfilled tape.
- 2026-08-21T20:09Z [claude-code] 2026-08-21 MIN CHECK PASSED on restored history. Over 1127 days (2023-07-20..2026-08-19) ZERO loans leave fully_paid after entering it (0 exit rows, 0 loans) — so PR #6413's MIN operator is justified by measurement, not by the 52-day window. Derived payoff dates for all 14: 4923612 -> 2025-05-27, EXACTLY the legacy datastore date, so the 35-day-early defect from the old closing-payment fallback is resolved by data. 13 of 14 predate 2026-06-29; earliest 2024-09-04 (21.8 months before the old tape start), confirming the 'up to 22 months early' figure in the PR body. Review gate is met: the diff is final and the PR can be marked ready. Before doing so, update the code comment '14 enter it and none exit across the tape on file' to cite 1127 daily tapes rather than the 52-day window. Merge still gated on: silver.positions rebuild + DEV_ABHISHEK validation + datastore comparison.
- 2026-08-21T20:51Z [claude-code] 2026-08-21 UNBLOCKED — bronze backfill and silver rebuild both done ([[wm-j5p44v]]). silver.positions openroad now covers 1128 days back to 2023-07-20; FULLY_PAID_DATE is still NULL on all 34079 rows because PR #6413 is unmerged. Remaining merge gate: (1) refresh DEV_ABHISHEK — it is STALE at 24 days / 2026-06-29..2026-07-22, so validating the branch there today would reproduce the exact bug; needs a re-clone from PROD first (edgefocus/data_warehouse/clone_snowflake_prod_db.py). (2) validate branch in DEV_ABHISHEK + Snowflake screenshots. (3) legacy-datastore comparison over full history — silver is now a strict superset of legacy (1128 dates from 2023-07-20 vs legacy 1123 from 2023-07-24; legacy's _Orl_-only INCLUDE_PATTERN never matched the four pre-rename LoanTape_Edge_ files). (4) merge. (5) final openroad_positions rebuild with as_of_date=all to populate FULLY_PAID_DATE. Review gate is already met (MIN verified over 1127 days), so the PR can be marked ready now.
