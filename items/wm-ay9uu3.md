---
id: wm-ay9uu3
type: task
title: Map FULLY_PAID_DATE for OpenRoad (DEV-1539)
status: active
size: s
people: [Abhijeet]
tags: [openroad, platform-data-owners]
links: [relates:wm-cgftbn, parent:wm-su6q4d]
refs: [DEV-1539=https://linear.app/edge-focus/issue/DEV-1539/add-fully-paid-date-mapping-for-openroad]
created: 2026-08-12T13:30:20Z
updated: 2026-08-20T19:47:35Z
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
