---
id: wm-rgwdyu
type: task
title: Migrate NorthPond Fund Monitoring page to Snowflake data (DEV-1395)
status: active
priority: p1
size: xl
due: 2026-07-20
tags: [northpond]
links: [parent:wm-j523sq]
refs: [DEV-1395=https://linear.app/edge-focus/issue/DEV-1395/migrate-the-northpond-fund-monitoring-page-to-use-snowflake-data, Grafana=https://grafana.edgefocuspartners.com/d/qQl7m9cHk/northpond-monitoring, PR5884=https://github.com/edgefocus/efp/pull/5884]
created: 2026-07-14
updated: 2026-07-17T09:22:36Z
source: dpx-tasks #1
label: NorthPond monitoring migration
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #1
- 2026-07-16T12:48Z [claude-code] PR #5884 OPEN and in progress (branch abhishek/dev-1395-northpond-at-purchase-features-and-payment, updated 2026-07-16). Shipped the v1/v2 (TU/Experian) filter for the per-loan at-purchase panels + populated silver.positions.MODEL_VERSION for northpond. The ~17 gold cashflow panels (IRR/ROI/CDR/CPR) are NOT covered by it — that is the follow-on wm-unb6pr.
- 2026-07-16T12:53Z [claude-code] CORRECTION to my 12:48Z entry (read from session ec4fd968 transcript, 12:40-12:47): the new NorthPond gold table is ALREADY REMOVED, not pending. Net diff vs master is now ONE new silver table, ZERO new gold: A silver/statement_rows/northpond/at_purchase_features.py (+test +tf), M northpond/positions.py (MODEL_VERSION +tests), M orchestration/assets/northpond_assets.py. at_purchase_features is a silver companion mirroring the existing per-platform *_credit_attributes convention, not a new pattern. ('gh pr diff' file list is misleading — per-commit, added+deleted within the PR; net diff is clean.) Three panels rewritten gold->silver: match the old gold numbers exactly (83.13% ACH on efhyf) and GAINED the v1/v2 filter the aggregate was structurally blocking (v1 0.8306 / v2 0.8463). Removal also surfaced dead code: gold DPD-bucket cols unused (positions_daily already has DPD buckets, no panel read them) and total_principal duplicated positions_daily.TOTAL_PRINCIPAL — only the connection-type split was ever used. 160 tests pass; both assets materialize green through Dagster; committed+pushed, CI queued 12:47.
- 2026-07-17T09:22Z [claude-code] Merge-feasibility analysis (asked by Abhishek 2026-07-17): can the NorthPond dashboard fold into Fund Monitoring (folder dfomia5rnkvlsd -> 'Fund Performance Monitoring' uid ffdec6db, 72 panels)? Verdict: possible but blocked; sequence AFTER this migration, not instead of it. HARD BLOCKER (data model, not Grafana): FPM assumes fund=>platform 1:1 and filters FUND='$fund' with NO platform filter across ~126 panels; all 5 fortress_* funds are 1:1, but efhyf spans 6 platforms (openroad,upgrade,marlette,prosper,anchored,northpond) — hence NorthPond's hardcoded PLATFORM='northpond' x99. Adding efhyf to FPM's dropdown yields SILENTLY WRONG aggregates: 110,281,094 loans/$79.9B UPB vs true northpond 169,421/$604M. True merge = thread a $platform var through every FPM panel, risking the 5 working funds. Secondary: NP-only at-purchase panels are NOT duplication — FICO is 92.9% NULL for northpond in SILVER.POSITIONS (0% for marlette/prosper/upgrade), which is why they read NORTHPOND_AT_PURCHASE_FEATURES. Convention deltas: NP GOLD.PREDICTED_CASHFLOWS_CALENDAR_MONTH vs FPM ..._FROM_PURCH (both have np rows, must pick); ${database} var vs hardcoded PROD; show_predicted 0/1 vs prediction_type none/at_orig/curr_mod/best_est (FPM superset, OP==at_orig); NP 80 flat panels vs FPM 8 collapsible rows. Compatible: same ds bqzSrsZvz, schemaVersion 42, shared $fund/$view_as_of_date idiom, 5 shared tables. FPM's warehouse/covenant layer (11 tables, ~35 panels) has no northpond equivalent. Recommended: cheap win = move dashboard into the Fund Monitoring FOLDER (zero query risk); defer panel merge until PR #5884 lands + northpond reaches PROD gold + platform-dimension design call is made with the FPM owner. Nothing changed — read-only analysis.
