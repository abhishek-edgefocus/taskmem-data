---
id: wm-y8kaaz
type: task
title: DEV_ABHISHEK is missing Snowflake streams that PROD has — transforms write rows then fail
status: done
priority: normal
size: s
tags: [snowflake, dev-env, terraform]
links: [relates:wm-u57a42]
created: 2026-08-26T15:50:26Z
updated: 2026-08-26T16:18:43Z
source: claude-code
---

`DEV_ABHISHEK` is missing Snowflake streams that exist in PROD and are declared in
`terraform/snowflake/`. Because the transform framework consumes a target stream
at the end of every run and reads source streams for incremental key discovery,
any transform whose stream is absent **writes its rows and then fails**, which
reads as a broken transform when it is an environment gap.

**Confirmed missing (2026-08-26), all present in PROD:**

| Stream | Table |
|---|---|
| `SILVER.API_CREDIT_ATTRIBUTES_STREAM` | shared credit-attributes table — affects **every** platform's `*_api_credit_attributes` transform |
| `BRONZE.PREDICTION_FILES_STREAM` | blocks `s3_prediction_files` from recording changed keys, so `s3_predictions` silently finds nothing to do |
| `SILVER.PREDICTED_CASHFLOWS_HISTORY_STREAM` | blocks `predicted_cashflows` entirely |
| `SILVER.NORTHPOND_STMT_ISSUANCE_STREAM` | source stream for the northpond credit-attributes transform |

`DEV_ABHISHEK.SILVER` had only **9** streams in total when this was found, and
`DEV_ABHISHEK.BRONZE` had **1**. So the four above are unlikely to be the whole
list — assume more will surface.

**Proof it is drift, not a code defect:** `openroad_api_credit_attributes.py`
(already on `master`, untouched by any current branch) run against DEV fails with
`Object 'DEV_ABHISHEK.SILVER.API_CREDIT_ATTRIBUTES_STREAM' does not exist`. The
table itself exists with `change_tracking = ON`, so nothing is wrong with it.

**Already created by hand** (mirroring their terraform definitions, so a later
`tf-apply` should be a no-op or a clean replace):
`SILVER.API_CREDIT_ATTRIBUTES_STREAM`, `SILVER.NORTHPOND_STMT_ISSUANCE_STREAM`,
`BRONZE.PREDICTION_FILES_STREAM`. `SILVER.PREDICTED_CASHFLOWS_HISTORY_STREAM` was
deliberately left, so `predicted_cashflows` still cannot run in DEV.

**The fix** is `make tf-apply` against `DEV_ABHISHEK` rather than more hand-created
streams — hand-creating them one at a time is what this session did, and each fix
only surfaced the next gap. Worth doing before the next validation pass that needs
the prediction chain, since it silently limits what any of us can prove in DEV.

Note the hand-created streams start at their creation offset, so they see no
history. Anything needing changed keys for existing rows has to force a change
(e.g. the `force=true` path on `s3_prediction_files`).

Context: found while validating DEV-1498 ([[wm-79k8df]], [[wm-u57a42]]).

## Log
- 2026-08-26T16:18Z [claude-code] FIXED 2026-08-26 at Abhishek's direction ('DEV_ABHISHEK is my database, just fix it'). DEV now matches terraform at 133 of 133 streams.

METHOD, so this is repeatable rather than a one-off. Parsed every resource block in terraform/snowflake/*.tf with a brace-matching parser (dp:~/claude-ws/dev-1498/parse_streams.py): 133 stream resources total — 132 snowflake_stream_on_table + 1 snowflake_stream — split SILVER 124 / BRONZE 6 / GOLD 3. Resolved each stream's target through its snowflake_table.<key>.name reference back to the table resource's literal name; 7 could not be resolved that way and fell back to the stream name minus the _STREAM suffix (the lc_stmt_* family), all of which reconciled against real DEV tables, so the fallback held. Then diffed against SHOW STREAMS / SHOW TABLES IN DATABASE for both DEV_ABHISHEK and PROD (dp:~/claude-ws/dev-1498/reconcile.py).

RESULT OF THE DIFF: 13 already present, 120 missing, 0 blocked. Every one of the 120 had its target table already present in DEV with change_tracking = ON, so no table had to be altered and no schema invented. All 120 also exist in PROD, so this was pure DEV drift with no terraform-vs-PROD disagreement.

APPLIED: 120 created, 0 failed, via CREATE STREAM IF NOT EXISTS with each stream's terraform comment carried over (dp:~/claude-ws/dev-1498/create_streams.py, --apply; idempotent, never drops or replaces, so re-running is a no-op). Re-ran the reconciliation afterwards: 133 already in DEV, 0 to create.

ONE THING NOT FIXED, and it is a table gap not a stream gap: PROD has SILVER.API_FIELD_PRESENCE_DAILY_STREAM, which terraform does NOT declare, and its table SILVER.API_FIELD_PRESENCE_DAILY does not exist in DEV either. The script checks for the table and correctly excluded it. Creating it would mean inventing a schema, so it was left. Worth knowing that PROD carries at least one stream outside terraform's control.

CAUTION FOR THE NEXT tf-apply AGAINST DEV, NOT VERIFIED: these 120 streams were created by hand, so terraform state does not know about them. Whether the provider treats a pre-existing stream as a no-op, an error, or something it wants to import was not tested. Check that before assuming tf-apply against DEV is clean.

ALSO WORTH KNOWING: creating the streams surfaced a backlog. Streams start at their creation offset so they see no history, but the pipelines that were previously failing now have real pending work in DEV — the first predicted_cashflows run after this picked up openroad statement keys alongside the northpond ones it was aimed at. Nothing wrong, just expect the first run of anything in DEV to do more than you asked for.
