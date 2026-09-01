---
id: wm-pdu67p
type: task
title: Deploy + replay the northpond purchase-tape fund fix in prod (PR #6557)
status: next
priority: p1
size: s
due: 2026-09-01
people: [Abhishek]
tags: [northpond, edgex]
created: 2026-09-01T09:38:55Z
updated: 2026-09-01T09:39:12Z
source: claude-code
---

PR #6557 (DEV-1711) merged 2026-09-01 09:35:46Z as 1285edd76. Fixes PURCHASE_TAPE_FUND_EXPR to read issuance_v2.INTENDED_INVESTOR first, so an EDGEX purchase no longer resolves to efhyf.

MERGING DOES NOT DEPLOY. deploy-dagster-prod.yml is workflow_dispatch only. Last prod deploy was 2026-08-31 18:42Z (its snowflake-tf-apply step FAILED; deploy/deploy succeeded) and the last fully green one was 2026-08-31 11:14Z - both BEFORE the merge. So the fix is not running in prod and new mislabelled rows keep accruing at ~20/day.

PROD DAMAGE as of 2026-09-01: 160 loans, $438,199.41 principal, transfer dates 2026-08-24..08-31, all booked northpond_balancesheet -> efhyf at par instead of edgex20261NN at 0.985. Price overstated $6,572.99. Separately 141 of 406 edgex20261NN positions rows carry NULL *_AT_PURCHASE because the pur join in positions_utils matches (POSITION_ID, TO_FUND).

STEPS, in order (Abhishek runs prod, not the agent):
1. Dispatch Deploy Dagster (prod). Watch snowflake-tf-apply - it failed on the 08-31 18:42Z run.
2. Replay, via the as_of_date run config (assets are stream-driven; a bare materialize is a no-op and rewinding ops.pipeline_watermarks does NOT help):
   northpond_stmt_purchase_tapes  config {"as_of_date": "2026-08-24:<today>"}
   northpond_transfers            config {"as_of_date": "2026-08-24:<today>"}
3. Run northpond_positions for the same range to repopulate *_AT_PURCHASE.
4. Verify: transfers TO_FUND=edgex20261NN and MARKUP=0.985 for all dates >= 08-24; positions *_AT_PURCHASE non-null on the 141.

Validated end to end in DEV_ABHISHEK and through the abhishek Dagster instance (port 13053, mounted from ~/repos/efp): 265 rows unchanged, 160 corrected, PRICE_DELTA -6572.99, at-purchase 141/141.
