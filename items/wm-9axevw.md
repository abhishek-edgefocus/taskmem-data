---
id: wm-9axevw
type: task
title: northpond datastore chain frozen at 2026-08-03: missing issuance_20260804.csv poisons standardized_positions every night
status: done
priority: high
size: s
tags: [northpond, datastores, oncall]
links: [relates:wm-tvjjgw, relates:wm-hjbt5a, parent:wm-3y3ckv]
created: 2026-08-12T14:10:51Z
updated: 2026-08-18T17:52:35Z
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

## Log
- 2026-08-12T20:47Z [claude-code] ABHISHEK'S TWO QUESTIONS ANSWERED 2026-08-12.

Q1 'if Oliv drops the Aug 4 file today, will that work?' — YES. The file must land at
s3://efp-raw/statements/northpond/issuance/2026/08/issuance_20260804.csv before the nightly
dumbledore run (~21:00 PT). generate_datastores re-assesses missing dates each run, so it will
build statement_loan_issuance 2026-08-04, then standardized_positions 2026-08-04, then the ~20
skipped dependents all catch up on their own. No code change, no manual re-run needed.
USEFUL DE-RISK: it does NOT have to be a true point-in-time Aug 4 snapshot. The gate is
set(positions.loan_id).issubset(set(issuance.loan_id)) — a SUPERSET passes. So even if Oliv
regenerates 'as of today' and just names it _20260804, it works, because issuance is cumulative
and the build only pulls 5 static per-loan attributes off it (application_uuid,
first_payment_due_date, state, annual_gross_income, origination_fee); as_of_date comes from the
build date, not the file. So the ask to Nate/Oliv can be loose.

Q2 'someone (Kushagra?) shared a Google Sheet where we drop file names to be ignored' — the
sheet is REAL and he remembered it correctly, but IT DOES NOT FIX THIS. Details in [[wm-j9jxpc]]:
Google Sheet 1gkWKElqMkgr7goxKS-s_L6xPNlAjGnr_3LhfgRMc7gY, tab 'Acknowledgements', hardcoded as
ACKNOWLEDGEMENT_SHEET_ID in edgefocus/monitoring/statement_file_acknowledgements.py; columns
PLATFORM, STATEMENT_TYPE, ACK_START_DATE, ACK_END_DATE, ACKNOWLEDGED_BY, UPDATE_DATE, REASON.
VERIFIED ITS SCOPE: the only non-test consumer is
orchestration/assets/statement_file_monitoring_assets.py:79 (evaluate_acknowledgements(results)
over a list[MissingFile]) — i.e. it suppresses the 'Missing Platform Data' alert / ERROR ticket
only. grep for 'acknowledg' across lib/efp/stats/ returns ZERO hits, so the dumbledore datastore
build has no knowledge of the sheet whatsoever. Acking 2026-08-04 would silence the alarm and
leave the datastore chain just as frozen. Worth remembering as a general rule: the ack sheet is
a monitoring construct, never a pipeline control.

Either real fix (Oliv re-drops, or copy issuance_20260803.csv to the _20260804 name) makes the
file exist, so no ack row is needed in either path.
- 2026-08-12T21:06Z [claude-code] PLAN CONFIRMED 2026-08-12 21:05 UTC: Abhishek is asking Oliv now to copy the file they delivered on Aug 3 and re-drop it labelled as Aug 4. This works — verified at the data level: all 715 loans in the Aug 4 loan tape are already in issuance_20260803.csv (0 extra), and extra issuance rows cannot leak because BOTH datastore consumers left-join issuance onto positions keyed on loan_id (datastore_standardized_positions_northpond.py:72, datastore_stand_pos_first_pass_northpond.py:72); the two other consumers (bin/reconcile/northpond/northpond_loan_fl.py, bin/northpond/owned_at_purchase_features.py) read full history and filter via .unique(), so they are date-order-insensitive. Use the 3rd NOT the 5th: the 3rd cannot contain a loan issued after the report date.

DELIVERY PATH (verified in repo): Oliv drops on SFTP (flat remote dir) -> Dagster job sftp_sync_northpond_job syncs SFTP->EFS /efs/data/statements/northpond/ on cron '30 * * * *' (hourly at :30, orchestration/definitions.py:297) -> [EFS->s3://efp-raw/statements/northpond/ leg NOT located in repo; SFTPSync writes EFS only and /efs/data is not mounted on dpx, so this hop is unverified] -> nightly dumbledore generate_datastores ~21:00 PT. Empirically the end-to-end lag is small: issuance files appear in S3 at a consistent 16:36-17:08 UTC daily. With the ask going out ~21:15 UTC there is ~7h of headroom before tonight's 04:00 UTC run, so it should catch tonight, but the unverified hop means it could slip a night. NOT a reason to delay the ask.

Told him the genuine Aug 4 file is the better ask if Oliv still has it (issuance is cumulative and generated daily, so what failed on Aug 4 was most likely the DELIVERY, not the generation).
- 2026-08-14T13:50Z [claude-code] RESOLVED + VERIFIED 2026-08-14. The copy-the-Aug-3-file plan worked end to end.

SOURCE FIXED: s3://efp-raw/statements/northpond/issuance/2026/08/issuance_20260804.csv now
exists, uploaded 2026-08-12 21:38, 125255 bytes — byte-for-byte the same size as
issuance_20260803.csv, i.e. Oliv re-dropped the Aug 3 file under the Aug 4 name exactly as
asked. August now has no gap: 08-01 through 08-13 all present.

CHAIN CAUGHT UP (checked s3://efp-derived/datastores/northpond/ on dpx today):
  standardized_positions/v1899/2026-08-13.parquet  written 2026-08-14 03:59
  positions/v1899/2026-08-13.parquet               written 2026-08-14 04:20
  transfers/v1899/transfers.parquet                written 2026-08-14 04:16
  cfframe/v1899/cfframe.parquet                    written 2026-08-14 04:59
So the two nightly runs since the file landed (2026-08-13 and 2026-08-14) rebuilt 08-04
onwards and the ~20 skipped dependents are current again. No code change was needed and none
was made.

Linear ERROR-1533 (missing_statement_file:northpond:issuance) was closed 2026-08-13 16:28 IST,
consistent with the above.

STILL WORTH DOING, but not here: options (b) prior-date fallback for a missing issuance file
and (c) stop one failed array index failing the whole datastore. Both are durable fixes for a
failure mode that has now recurred at least six times (2025-12-01, 2026-01-06..11, 2026-02-04/05,
2026-02-13, 2026-08-04). Neither is captured as its own item yet — raise if wanted.
- 2026-08-18T17:52Z [claude-code] EFS->S3 hop RESOLVED 2026-08-18 (via cross-session peer abhishek-69, relayed through abhishek-da). Previously marked unverified in this item's body (DELIVERY PATH section). It's the copy_from_efs Dagster asset calling copy_efs_to_s3() in edgefocus/transformations/bronze/strip_statement_pii.py - routes PII-flagged files to efp-pii and everything else to efp-raw. So the full chain is now: Oliv SFTP -> sftp_sync_northpond_job (hourly :30) -> EFS /efs/data/statements/northpond/ -> copy_from_efs asset / copy_efs_to_s3() (PII-routing split efp-pii vs efp-raw) -> s3://efp-raw/statements/northpond/... Not independently verified by me in this session, but two peer sessions cross-confirmed it.
