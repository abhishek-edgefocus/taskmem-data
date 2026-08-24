---
id: wm-qu4cr7
type: task
title: Investigate 15 northpond loans missing from gateway model_responses (ERROR-1231)
status: open
priority: p2
size: m
tags: [oncall]
links: [parent:wm-3y3ckv]
refs: [ERROR-1231=https://linear.app/edge-focus/issue/ERROR-1231/northpond-issued-missing-gateway-responses-15-issued-northpond-loans]
created: 2026-07-14
updated: 2026-08-24T13:06:27Z
source: dpx-tasks #7
label: NorthPond 15 missing loans
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #7
- 2026-08-24T12:59Z [claude-code] ROOT-CAUSED 2026-08-24. The ticket's stated cause is stale and wrong today. Alert source is bin/northpond/issued.py:114-123 (added by Kabeer PR #5390, 2026-06-01, ERROR-127): it reconciles the cumulative issuance CSV against gateway MySQL northpond.model_responses, posts a Sentry error listing unmatched application_uuids, and SKIPS them from the northpond.issued table permanently. Sentry EFP-ERRORS-15E (81 events, first 2026-06-02, still firing daily 08:00 UTC, latest 2026-08-24). Count has grown 15 -> 25.

VERIFIED AGAINST PROD (read-only, gateway MariaDB grafana-mariadb RDS + S3):
- The current 25 have NO model_requests row AND no model_responses row. Kabeer's 'in model_requests but no model_responses / EFP made no offer' cohort is now EMPTY (0 of 1339 issuance apps) - those May loans reconciled. The 25 are a different, later cohort.
- The 25 are a contiguous loan_id block 12563327-12563357, all first_payment_due 2026-08-02..08-08, total 56,500 amount_financed. All 25 present in the cumulative issuance file; 1314 of 1339 issuance apps reconcile fine.
- REAL CAUSE: the gateway->MySQL loader bin/northpond/grafana.py did not run for 2026-07-02, 07-03, 07-04 and only partially on 07-01. MySQL northpond.model_requests/model_responses have ZERO rows for 07-02/03/04 and 154-263 on 07-01 (vs ~712/day). The gateway itself was healthy: S3 s3://efp-raw/gateway/northpond/northpond_loan_fl/<date>/v2/model_requests|model_responses holds 761/589/781/541 objects for 07-01..07-04. Heartbeat EFP-ERRORS-GW 'northpond:grafana has not checked in' (ERROR-593) fired across that window, last event 2026-07-06. Nobody backfilled when it recovered.
- GATEWAY-WIDE, not northpond: sofi.model_responses and openroad.model_responses also have ZERO rows on 07-02/03/04 while sofi S3 holds 7656/6486/4461 model_responses objects those days. Every platform's gateway Grafana panels have a 3-day hole.
- Bounded and stable: nothing after the July window is unreconciled; issued is current to loan_id 12563910 / 2026-08-23.

FIX (prod run, Abhishek only): bin/northpond/grafana.py --date 2026-07-01,2026-07-02,2026-07-03,2026-07-04. Safe to re-run: process_model() reads existing gateway_ns for the date and only inserts missing URIs, and writes with on_duplicate_key_update=True (model_requests UNIQUE request_uuid, model_responses UNIQUE offer_uuid). Caveat: the same run also calls add_perf_data(), a plain append into northpond.performance - but that table is already appended on every ~21m run (224 dates have >1 row; 07-01..07-04 currently have 0), so backfilling those four dates fills a gap rather than duplicating. After the backfill the next daily issued.py run picks the 25 up automatically (they are not in issued, so the existing-loan_id filter does not block them) and the alert stops.

SECONDARY: a duplicate Linear ticket ERROR-1721 was minted 2026-08-21 from a second Sentry issue EFP-ERRORS-1P8 carrying the same message (its title embeds the loan-id list, so it fingerprints separately). Dedupe against ERROR-1231.
DESIGN BUG worth a separate ticket: issued.py skips unreconciled loans forever and re-alerts every day; it has no retry/backfill path and no bound, so any gateway-loader gap becomes a permanent daily alert.
- 2026-08-24T13:06Z [claude-code] Addendum 2026-08-24: openroad independently confirmed on the same footing as sofi. S3 s3://efp-raw/gateway/openroad/openroad_auto_refi/ holds 486 model_responses objects on 2026-07-02 and 241 on 2026-07-04, while openroad.model_responses MySQL has ZERO rows on both days. (An earlier sofi check in this session returned all-zero counts but was a bad invocation - 'aws s3 ls --exclude' is not a valid filter; the corrected run gave 7421/7656/6486/4461/4395 objects for 07-01..07-05. Use grep on a plain --recursive listing, not --exclude.) Diagnosis and fix unchanged.
