---
id: wm-uc6eaz
type: bug
title: marlette standardized_positions fails nightly since 2026-09-18: 105 edgex20261NN loans unscorable because Marlette sent header-only originations files 2026-05..09-16 (PD #1455/#1456)
status: open
priority: p1
tags: [oncall, pagerduty, marlette, edgex, data-freshness]
created: 2026-09-24T12:09:23Z
updated: 2026-09-24T12:09:37Z
source: pd-1455
---

PD #1455 + #1456 are ONE failure (same subject, same second, two apps -> two Grafana
dedup keys; efp-coder has no alert grouping). Root cause traced end to end.

## Chain
1. Marlette's `marlette_originations_*.csv` (the credit-attributes / Experian
   originations file) went **header-only from 2026-05 through the 09-16 file**.
   Data-bearing counts per month in `s3://efp-raw/statements/marlette/`:
   2026-04=19, **05=0, 06=2, 07=0, 08=0**, 09=5 (only 09-17,18,19,22,23).
   Files arrive daily and are 13,924 bytes = 1 line, header only.
   Verified: `marlette_originations_20260915.s.csv` and `...20260916.X.csv` = 1 line;
   `...20260917.X.csv` = 41 lines. File date = funded date + 1 (41-1 = 40 rows =
   bronze AS_OF_DATE 2026-09-16 count of 40).
2. So `bronze.statement_rows` (marlette/credit_attributes) and
   `silver.marlette_stmt_credit_attributes` both hold NOTHING between 2026-04-24
   and 2026-09-15 (one bulk catch-up on 06-11, 11,983 rows, older vintages).
   Bronze == silver exactly, so the transform is fine — the vendor sent empty files.
3. 105 marlette loans originated 2026-09-14/15, purchased 09-17/18 into
   `edgex20261NN`, $1,881,689 principal, channel `hyp_forward_flow`.
   They have **0 rows** in `silver.marlette_stmt_credit_attributes`
   (the 102 loans purchased 09-21/22 have 40/40 and 62/62 coverage).
4. `MarletteEdgexPredictor` is a `ForwardFlowPredictor`: features come from
   `silver.marlette_stmt_credit_attributes`. No credit row -> no features ->
   batch skipped -> **0 predicted_cashflows, 0 silver.ef_scores rows** for all 105.
5. `silver.positions.EF_SCORE` is therefore NULL on those 105 edgex20261NN rows.
6. `add_ef_score` (datastore_standardized_positions.py:1760-1765) hard-raises on a
   NULL ef_score in a settled EDGEX fund -> `[DatastoreStandardizedPositions]
   [marlette] Failed to generate datastore` -> **~35 dependent marlette datastores
   skipped** ("Dependent datastore errored") every night.

## Status: NOT transient, NOT recovered
- Failing every night since the **2026-09-18** run — 6 consecutive nights (09-18,
  19, 20, 21, 22, 23), all 6 array children FAILED, exit 1, "Essential container
  in task exited". Array size grows 1->6 because each night adds another pending
  as_of_date.
- `alert_status` on both incidents is still `triggered`.
- `pd-history.py generate_datastores_ubuntu`: 83 occurrences in 21d.

## This is NOT the bug Kabeer already fixed
`f0105a7cf` / PR #6680 (merged 2026-09-07) fixed the *ordering* case — 2 loans on
the permanent-ignore list scored before the invalid/sold drops. That fix IS
deployed (`/efp/scripts/.../datastore_standardized_positions.py` calls
`add_ef_score` at line 832, below the drops, identical to origin/master).
Same error message, different cause. So wm-5vrgzp's premise ("Kabeer is looking
into it") no longer applies to this recurrence.

## Cohort is bounded
Purchase lag is ~3 days, and the feed resumed with fundings from 09-16, so only
loans funded 09-14/15 are exposed: exactly the 105. Everything purchased 09-21
onward is scored (102/102). It reopens only if marlette sells loans funded in the
05-01..09-15 empty-file window into an EDGEX fund.

## The decision he owns
Two options, real trade-off:
- **Ask Marlette to re-deliver originations data for 09-14 + 09-15 fundings**
  (2 days). Permanent fix, restores the CL denominator. Vendor-dependent, so not
  tonight. We do not synthesise vendor files.
- **Soften the `add_ef_score` gate** for loans with no credit-attributes row, the
  way the to_be_purchased case is already warn-only (comment at :1756-1759).
  Unblocks ~35 marlette datastores now, but leaves $1.88M of unscored principal in
  the denominator of all ten edgex20261NN concentration limits and the numerator of
  none — they read artificially low. Eshan's DEV-1677 (#6624, 09-18) already
  records this as an advisory rule, so it is visible rather than silent.

## Monitoring gap this proves
A header-only file grades as "arrived". The feed was empty for ~4 months and
nothing flagged it. This is exactly [[wm-zgx7tj]] ("false green on
marlette/credit_attributes"), opened 2026-09-16 — the day the feed resumed.
