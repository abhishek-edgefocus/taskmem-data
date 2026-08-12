---
id: wm-9axevw
type: task
title: northpond datastore chain frozen at 2026-08-03: missing issuance_20260804.csv poisons standardized_positions every night
status: next
priority: high
size: s
tags: [northpond, datastores, oncall]
created: 2026-08-12T14:10:51Z
updated: 2026-08-12T14:10:55Z
source: claude-code
effort: <1h
---

Found 2026-08-12 answering "check northpond datastores and why is it stale".
Read-only investigation; nothing was changed.

## Symptom
Everything downstream of standardized_positions is frozen at 2026-08-03 18:40 PT
(datastore artifacts under s3://efp-derived/datastores/northpond/, index v1899):
positions, payments, open/closed/delta_positions, transfers, ownership,
ownership_by_fund, cfframe, cfframe_from_purch, calendar_month_* , mob_*,
pred_cfframe_at_orig, pred_cfframe_from_purch, true_pred_cfframe_at_orig,
pred_payments_at_orig.
The statement-level readers are FINE and ran this morning through 2026-08-11
(statement_loan_positions / _issuance / _transactions, stand_pos_first_pass, transactions
all written 2026-08-12 03:08-03:34).
NOT a global break: sofi and happymoney standardized_positions are current (2026-08-10,
written 2026-08-12). marlette/prosper/upgrade/openroad positions are ancient (2024, v996/v998)
for unrelated reasons.

## Root cause (confirmed end to end)
`issuance_20260804.csv` was never delivered. s3://efp-raw/statements/northpond/issuance/2026/08/
holds 08-01, 08-02, 08-03, 08-05 ... 08-11 — 08-04 is the ONLY gap in the month.
The loan tape for that day arrived normally (ffcnp_dailyloantape_08042026.csv, 278046 bytes).
northpond is NOT in BaseStatement.PLATFORMS_WITH_ONE_DAY_LAG_AS_OF_DATE, so datastore
date D reads issuance_D.csv — no lag to absorb the gap.

Chain:
1. No raw file -> no statement_loan_issuance/v1899/2026-08-04.parquet (verified absent;
   statement_loan_positions/v1899/2026-08-04.parquet exists).
2. datastore_standardized_positions_northpond.py:102 checks
   set(positions.loan_id).issubset(set(issuance.loan_id)); with an empty issuance frame that
   fails trivially -> line 108 self._raise_exception(
   "Found extra loans in the positions file which are not in the issuance").
3. AWS Batch array job index 0 (= date 2026-08-04) exits 1; the parent sees
   "Essential container in task exited which will not be retried"
   (efp/lib/efp/batch.py:1942) and marks the WHOLE datastore failed for northpond, even though
   array indices 1-7 (dates 08-05..08-11) all SUCCEEDED and were written.
4. generate_datastores.py logs "All datastores dependent on datastore_standardized_positions
   will be skipped for northpond" -> ~20 dependents skipped.

## THE LOANS ARE FINE — this is a missing-file problem, not a data-quality problem
Loaded the 08-04 positions parquet directly: 715 rows, all 715 survive the BoardingDate <
ReportDate filter. Set difference against the ADJACENT issuance files:
  vs issuance 2026-08-03 (931 rows): 0 extra
  vs issuance 2026-08-05 (966 rows): 0 extra
So there is not a single genuinely-unissued loan. The exception is purely the absent file.
(Issuance is cumulative — row counts grow monotonically day over day.)

## It will never self-heal
8 consecutive nightly failures so far: 2026-08-04, 05, 06, 07, 08, 09, 10, 11 (all
21:00-21:20 PT). The run re-attempts the same poisoned 2026-08-04 date every night and will
keep doing so until either the raw file appears or the code stops treating one bad date as a
whole-datastore failure. Earlier occurrences of the same exception exist (2025-12-01,
2026-01-06..11, 2026-02-04/05, 2026-02-13), so this failure mode recurs.

## Options (not yet discussed with anyone)
(a) Ask Nate/Oliv to re-send issuance_20260804.csv — cleanest, fixes it at source, but needs
    a human on their side and the chain stays stuck meanwhile.
(b) Make build_northpond fall back to the most recent PRIOR issuance date when the exact date
    is missing. Safe because issuance is cumulative and the prior day can never contain a loan
    issued after the report date. This is the durable fix for a recurring failure mode.
(c) Stop one failed date failing the whole datastore — array indices 1-7 already succeeded;
    the all-or-nothing rollup in base_datastore.process_jobs_return_values is what converts a
    single-day gap into 8 days of total staleness across 20 datastores.
(b) and (c) are independent and both worth doing; (c) is the higher-leverage one and is not
northpond-specific.

## Separately: the purchase tape is stale for a DIFFERENT reason
statement_purchase_tape is frozen at data date 2025-06-16 (last written 2026-06-18) because
its feed s3://efp-derived/trades/northpond_ff/ stops at "Pool 6 ... 06172025.xlsx".
That is [[wm-tvjjgw]] materialising: real purchases resumed 2026-08-11 and 2026-08-12 but land
at s3://efp-raw/statements/northpond/purchase_file/v0/2026/08/purchase_file_v0_2026081{1,2}.csv,
which the legacy xlsx-pinned reader cannot see. Track that there, not here.

## Evidence trail
- prod log /efs/logs/dumbledore/generate_datastores_ubuntu.log (dumbledore, via populate_efp_stats.sh)
- failing batch array job 06c8d2f5-0587-4416-950e-627ba66913fe:0
- CloudWatch /aws/batch/job stream job-definition/default/cdc7d9144ab5475cba1c711cc9bf0d08
- repro script kept at ~/claude-ws/np-datastore-stale/ on dpx
