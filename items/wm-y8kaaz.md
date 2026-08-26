---
id: wm-y8kaaz
type: task
title: DEV_ABHISHEK is missing Snowflake streams that PROD has — transforms write rows then fail
status: next
priority: normal
size: s
tags: [snowflake, dev-env, terraform]
created: 2026-08-26T15:50:26Z
updated: 2026-08-26T15:50:26Z
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
