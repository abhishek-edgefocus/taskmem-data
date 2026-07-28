---
id: wm-fzbz7m
type: task
title: DEV-1468: ingest Oliv issuance_v2 + retarget at_orig predictions to Oliv ANL
status: done
priority: p0
size: l
due: 2026-07-24
people: [Nakula, Nate, Trishit]
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-c5jytx, relates:wm-embhpy]
refs: [DEV-1468=https://linear.app/edge-focus/issue/DEV-1468/retarget-northpond-at-orig-predictions-to-olivs-anl-issuance-v2, PR=https://github.com/edgefocus/efp/pull/5993]
created: 2026-07-23T10:33:14Z
updated: 2026-07-28T17:36:41Z
source: claude-code
---

## Log
- 2026-07-23T10:33Z [claude-code] CREATED 2026-07-23 from a Linear/GitHub sweep — this work was in flight since 2026-07-22 with no taskmem item. DEV-1468 'Retarget NorthPond at_orig predictions to Oliv's ANL (issuance_v2)', created 2026-07-22 18:32Z, status In Progress, no priority set in Linear. It is the concrete implementation of [[wm-c5jytx]]'s method and supersedes its steps 2-3 for the retarget half.

SPLIT INTO TWO PRs. PR #5993 (DRAFT, ingestion half) is up: bronze northpond_issuance_v2 parsing rule covering all three plausible delivery layouts (unmonitored for now — a start_date before deliveries stabilise would alert on the whole back-range), new silver.northpond_stmt_issuance_v2 narrow projection (2 identifiers + iccm_score/cgl/anl only), nullable TARGET_ANL on silver.predictions, NorthpondAPIPredictions joins v2 and emits TARGET_ANL with a second stream source + expand_keys for late arrival, new orchestration asset in statements_northpond with northpond_api_predictions depending on it. 11 files incl. 2 terraform schemas. Explicitly changes NO existing number. The retarget that consumes TARGET_ANL is a SECOND, UNWRITTEN PR — scaling happens at first use in PopulatePredictedCashflows, not at ingestion, so raw model output is preserved.

JOIN-KEY GOTCHA worth keeping: v2 drops the integer loan_id for the OLV-prefixed oliv_loan_number (same key as the purchase file). 'northpond_' || OLIV_LOAN_NUMBER reproduces EFP_ID exactly. Would have failed SILENTLY otherwise — v1's additional_where filters RAW_RECORD:loan_id != '', which drops every v2 row.

CI: 4/5 checks pass (integration, Select tests, Seer, Cursor Bugbot). The one FAILURE is 'Run Tests' and it is NOT a test failure — ruff format --check reports 'Would reformat: edgefocus/transformations/silver/statement_rows/northpond/northpond_constants_test.py, 1 file would be reformatted, 2390 already formatted'. One ruff format + push clears it.

Nakula asked on the Linear issue 2026-07-22 18:35 'How do we plan to do this? Will it point to a new model that Trishit will deploy?' — Abhishek answered 18:52: 'New Model Preds = Old Model Preds * (Oliv's ANL / Our ANL)'. Answered, no open thread.

COMMITMENT MADE TO OLIV: Abhishek told the group DM 2026-07-22 16:25 'We are planning to update our pipeline to support these new fields and compute the new predictions and cash flows by Friday' — i.e. by 2026-07-24. That is both PRs plus a run, and the k-denominator question ([[wm-embhpy]], the 1.36 net-vs-gross issue) is still unasked.
- 2026-07-24T13:05Z [claude-code] CORRECTION 2026-07-24: earlier notes (wm-embhpy log, 2026-07-23) said the issuance_v2 scope was "Shipped in PR #5993 (DEV-1468)". That is MISLEADING — PR 5993 "DEV-1468: Ingest Oliv issuance_v2 into a dedicated silver table" is still OPEN, mergedAt=null. Verified 2026-07-24: no issuance_v2 parsing rule exists on origin/master, and there is no terraform/snowflake file for the silver issuance_v2 table.

CONSEQUENCE IN PROD: the file IS delivered and synced — s3://efp-raw/statements/northpond/issuance_v2/2026/07/issuance_v2_20260723.csv, 114,053 bytes, 2026-07-23 18:07:18 UTC (Nate placed it 17:03:50 UTC; ~63 min sync lag). But PROD.bronze.statement_files has it as status=unknown with rule_name NULL, there are zero issuance_v2 rows in bronze.statement_rows, and PROD.SILVER.NORTHPOND_STMT_ISSUANCE_V2 does not exist. DEV_ABHISHEK does have the table + NORTHPOND_STMT_ISSUANCE_V2_STREAM, which is why it looked done from the dev side.

ALSO: only ONE issuance_v2 file exists (20260723). Nate has not produced a 07-24 one, despite Abhishek saying on 2026-07-24 18:21 IST "I am yet to validate the issuance v2 file. Lmk whenever you drop it" — the file he is waiting for is already there. Nate confirmed this with two screenshots at 18:25 IST showing edge-focus/issuance_v2/2026/07/ containing exactly issuance_v2_20260723.csv.

USEFUL DERIVED FACT for path work: those screenshots prove Oliv SFTP root edge-focus/ maps to our s3://efp-raw/statements/northpond/. So Nates proposed /purchase_file/v0/{YYYY}/{MM}/ will land at s3://efp-raw/statements/northpond/purchase_file/v0/{YYYY}/{MM}/.
- 2026-07-24T18:37Z [claude-code] QR confirmed: retarget applies to DEFAULT probabilities only, not prepay. PR #6015 updated (19dbaa57a) — prepay now written straight off the payload, unscaled/unclamped. This also settles the open tie-out question: default-only measured 1.03% mean abs error vs Oliv's ANL, vs 4.68% when both curves were scaled.
- 2026-07-24T19:12Z [claude-code] E2E test passed in local dagster (DEV_ABHISHEK): issuance_v2 -> api_predictions -> predicted_cashflows -> ef_scores. 83 Oliv-ANL loans scored. EF_ANL lands 1.03% mean abs from Oliv's ANL (vs 26.4% off our own model), 82/83 in the same EF bucket as an exact ANL. Prepay confirmed unscaled (2988/2988 ratio exactly 1.0); 25,812 non-Oliv rows byte-identical (control). Two DEV-env blockers fixed: SILVER.EF_SCORES was a stale 4-col clone (terraform has 7) so ef_scores crashed on PREV.S3_BASE — added S3_BASE/AS_OF_DATE/PLATFORM + EF_SCORES_STREAM; silver.predicted_cashflows in DEV is still a VIEW onto PROD so verification used predicted_cashflows_history.
- 2026-07-24T19:58Z [claude-code] PR #5993 (DEV-1468) merged to master 2026-07-24T18:30Z. PR #6015 (DEV-1445) rebased onto master and retargeted base master->4 files, MERGEABLE, REVIEW_REQUIRED. PROD BLOCKER: silver.northpond_stmt_issuance_v2 + its stream do NOT exist in PROD yet — terraform is manual (make tf-apply) and has not run since the merge. Deploying either PR before tf-apply breaks northpond_api_predictions (existing asset). Prod dagster deploy is manual workflow_dispatch so merging is safe. Secondary: 88/115 Oliv loans already have at_orig predictions in PROD and 33 have locked EF scores, so the retarget only reaches new loans; a backfill would need --date 2026-07-02:2026-07-23 (22 dates) plus clearing those loans' cashflow history. Blast radius zero: 0 Oliv loans in PROD positions.
- 2026-07-24T20:06Z [claude-code] CORRECTION to earlier note: EF scores are NOT frozen by MIN(GENERATION_TS). predicted_cashflows REPLACES history by s3_base rather than appending, so there is exactly one generation per loan (verified 800/800 DEV, 805/805 PROD) and MIN() always resolves to the current one. Verified 800/800 np EF_ANL match current cashflow-derived ANL, 0 stale. No manual clearing of cashflow history is needed for a backfill — just re-run northpond_api_predictions. Note statements_northpond job does NOT contain predicted_cashflows/ef_scores; those sit in ingest_prediction_files which runs on */30 * * * *, so they follow automatically within 30 min.
- 2026-07-27T19:18Z [claude-code] PROD go-live verification (2026-07-28): retarget itself is CORRECT — predictions 3708/3708 default=raw*k, prepay unscaled, 0 out of range; non-Oliv 25812/25812 untouched; cashflows for all 103 scored Oliv-ANL loans land 1.01% mean / 0.57% median / 4.67% max off Oliv (matches DEV exactly). BUT silver.ef_scores is STALE for 33 of 103 loans: their EF_ANL still equals our un-retargeted model ANL (off Oliv by up to 87%), even though their cashflows ARE retargeted. Root cause: ef_scores is lock-once + stream-scoped; the 33 stale loans were first scored 2026-07-10 (LOADED_AT 07-10, pre-retarget) and the retarget run's ef_scores pass (12:07, refreshed 55) did NOT re-derive them. ~10 loans currently in a wrong EF bucket. Cashflows are single-generation and correct, so fix = force ef_scores to re-derive the 33 (as_of=all or scoped to their batches) from existing cashflows; no cashflow rebuild needed. Will NOT self-heal (no pending cashflow change to retrigger). Did read-only analysis only; left execution to Abhishek.
- 2026-07-28T17:36Z [claude-code] DONE — verified against GitHub + Linear 2026-07-28. Both halves shipped and live in prod:
- PR #5993 (ingestion: bronze issuance_v2 rule, silver.northpond_stmt_issuance_v2, TARGET_ANL on silver.predictions) MERGED 2026-07-24T18:30Z, approved.
- PR #6015 (DEV-1445, the retarget itself) MERGED 2026-07-27, approved.
- Linear DEV-1468 status Done (completed 2026-07-24T19:33Z); DEV-1445 status Done (completed 2026-07-27T18:53Z).
Prod go-live already verified on this item 2026-07-27/28: predictions 3708/3708 default=raw*k, prepay unscaled, 0 out of range; non-Oliv 25812/25812 untouched; cashflows for all 103 scored Oliv-ANL loans land 1.01% mean / 0.57% median / 4.67% max off Oliv's ANL.
The item sat in 'next' with due=2026-07-24 for four days after the work was actually finished — it should have closed on 07-27 when #6015 merged.
ONE REAL REMAINDER, spun out rather than left buried here: silver.ef_scores is stale for 33 of 103 loans (~10 in a wrong EF bucket) because ef_scores is lock-once + stream-scoped and did not re-derive them. Tracked separately.
