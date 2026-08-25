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
updated: 2026-08-25T15:01:55Z
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
- 2026-08-24T15:07Z [claude-code] BILLING IMPACT found 2026-08-24 - this is not just dashboard noise. bin/northpond/generate_monthly_fee.py (dumbledore cron '0 11 3 * *') builds NorthPond's monthly invoice from these exact tables and POSTs it to a Zapier webhook -> QuickBooks, plus Slack #north-pond. Two lines, both hit by the July gap:
 (1) $2 per Direct application, from model_requests.date_utc in month. Missing rows: 07-01 498 (761 S3 objects vs 263 in MySQL), 07-02 589, 07-03 781, 07-04 541 = 2,409 applications absent. Direct share on healthy neighbouring days is 1.7-3.5%, so ~40-85 Direct apps = ~$80-170 under-billed.
 (2) 0.5% of amount_financed on funded non-Direct loans, from issued JOIN model_requests filtered on issued.date_first_seen in month. The 25 skipped loans = $56,500 -> $282.50 under-billed.
 Combined July 2026 shortfall ~$360-450. The July invoice was generated and sent on 2026-08-03.
DO NOT re-run generate_monthly_fee.py for July - it would push a SECOND invoice to QuickBooks. The correction has to be a manual credit/adjustment, and is a conversation with whoever owns NorthPond billing, not a script.

CORRECTED FIX SEQUENCE (2 steps, order matters):
 1. bin/northpond/grafana.py --date 2026-07-01,2026-07-02,2026-07-03,2026-07-04
 2. bin/northpond/issued.py --date 2026-07-01,2026-07-02,2026-07-03,2026-07-04,2026-07-05,2026-07-06,2026-07-07
Step 2 MUST pass --date. issued.py stamps date_first_seen = the issuance-file date it is processing; run bare (default --start yesterday --end today) it would stamp today's date and drop the 25 loans into the AUGUST billing period instead of July. Verified first-appearance dates by walking the July issuance files: 07-01 x1 ($1,000), 07-02 x6 ($9,000), 07-03 x9 ($25,000), 07-04 x4 ($8,000), 07-05 x2 ($6,000), 07-06 x1 ($1,500), 07-07 x2 ($6,000); all 25 matched.

WHERE IT RUNS: execution/cron/dumbledore/ubuntu/existing.cron:236 '*/5 * * * * cd /efp/scripts && python bin/northpond/grafana.py --verbose' and line ~226 '0 1 * * * python3 /efp/scripts/bin/northpond/issued.py', both as ubuntu@dumbledore.edgefocus.net. Jenkins 'Cron Scripts - Dumbledore' is a DEPLOY job only (run_tests.sh + rsync to /efp/scripts + deploy-crontab.sh) - it cannot run an ad-hoc backfill, and the repo JenkinsClient is read-only by design.
NOT HOST-BOUND: both scripts only touch S3 efp-raw and the shared MariaDB grafana-mariadb.c7attyszx6bg.us-east-2.rds.amazonaws.com (user default-writer from configs/default_passwords.json). Both are reachable from dpx - this session read those tables from dpx. /efp/scripts is just the deployed checkout. To run from dpx: repo .venv is missing termcolor (efp.terminal imports it); and grafana.py's add_perf_data() may fail on dpx if StatementLoanPositions needs datastore/EFS access, but it runs AFTER both process_model() calls so the model_requests/model_responses writes would already be committed. UNVERIFIED: whether the default-writer grant permits writes from dpx's IP (only reads were tested). dumbledore.edgefocus.net resolves to 172.31.33.180 and tcp/22 is open from dpx, so access is a key/account question not a network one - untested, the ssh attempt was blocked in-session.
- 2026-08-24T18:23Z [claude-code] CORRECTION 2026-08-24 — read the actual Linear thread (Linear MCP finally authorized). Abhishek was right to challenge my framing. The ticket's ORIGINAL subject is a different problem from what I investigated, and he already fixed it.

WHAT ERROR-1231 WAS ACTUALLY ABOUT (the original 15, June 2026):
 - Description field is EMPTY; title is just the alert text. Nothing about Grafana anywhere - his instinct was correct.
 - The 15 uuids (2d012331-bf1b-4b3a-9007-9cda4e117a2b, 459b73d6-..., 595719fc-..., 67a78726-..., 6bdb1da3-..., 7a44ab9d-..., 8652a7b2-..., 8f849274-..., 8fd5a27f-..., ac5deb65-..., b53a330f-..., ccc6acf6-..., cf3aee81-..., e257adfe-..., ee2ba0c8-...) share ZERO overlap with the 25 currently firing.
 - Root cause (found by Abhishek 2026-07-01, NOT the loader): application_uuid was CORRUPTED in model_responses, so the reconcile join failed. The fix in PR edgefocus/efp#5068 'preserve application_uuid through NorthPondExpOfferModel' (2026-04-20) never reached the prod model container - Jenkins 'Endpoint - NorthPond / Production - Model and Gateway Task' build #61 deploys the model from git tag model_northpond_exp, and that tag still pointed at a 2026-03-23 commit. Gateway ran master HEAD while the model stayed pinned to the stale tag. Kabeer 2026-07-01: 'this looks like a miss from my end, i ran the deployment without retagging'.
 - RESOLVED by Abhishek: new tag model_northpond_exp_20260701_191417_UTC, Jenkins build #62 green (2026-07-01 19:39 UTC); then 2026-07-15 'Recovered the real application_uuid for all corrupted model_responses. The 15 loans are now ingested and reconcile passes.'
 - This also corrects Kabeer's PR #5390 premise ('EFP made no offer on them') - the real cause was a corrupted join key, not a missing offer.

WHY IT IS STILL OPEN: the alert is STATELESS and the Sentry subject is stable, so a NEW cohort re-opens the SAME Linear ticket. State history: Done 2026-07-01, Done again 2026-07-15, bounced back to Backlog 2026-07-16T08:27Z and Backlog ever since. Eshan flagged 2026-07-20 'it has moved back from Done'. So the 25 loans I diagnosed (gateway->MySQL loader gap 07-01..07-04) are the CURRENT cause of the reopen, not the ticket's original subject. Both are true; I wrongly described the ticket as being about the loader gap.

SUSPICIOUS TIMING worth checking: the model/gateway redeploy (build #62) completed 2026-07-01 19:39 UTC, and the MySQL model_requests/model_responses rows stop partway through 07-01 and are absent 07-02..07-04. S3 gateway logs are complete throughout. Possible the redeploy is what broke the loader - unproven, but the coincidence is tight.

OPEN: Sanjali Agrawal commented 2026-08-24T06:05Z '@abhishek any updates on this?' - Abhishek owes a reply today. Ticket is Backlog, priority High, assignee Abhishek Doshi, team Errors, label 'Data Ingestion'.
STILL OPEN TECHNICALLY: 22 of the current 25 confirmed present in S3 gateway model_responses for 07-01..07-04 (reader validated by control, 553/553 on 07-05); 3 remain unexplained - worth testing whether those 3 are the corrupted-application_uuid pattern recurring rather than the load gap.
- 2026-08-24T20:09Z [claude-code] CORRECTION 2026-08-25 (Abhishek spotted it): the 'Northpond Billing' Grafana dashboard (uid b213468c-71f8-4326-802c-640f2bd69fe8) is NOT affected by the MySQL gap. All 3 panels use the Snowflake datasource (michelin-snowflake-datasource, uid bqzSrsZvz) and read PROD.bronze.api_events (event_type='model_requests') + silver.northpond_stmt_issuance. My earlier '4 refs to model_requests' was a naive string match on the dashboard JSON - it matched the Snowflake event_type filter, not the MySQL table. Its header panel literally says 'Computed from Snowflake'.

WHAT STILL STANDS: the actual invoice is NOT the dashboard. Verified against origin/master (99c70e725, my checkout 0984f1a4f was behind): bin/northpond/generate_monthly_fee.py line 46 still DATABASE = DB('stats-efp','northpond') = MySQL, line 86 direct_fee = direct_apps * 2, line 127 non_direct_funded_amt * 0.005. It is the script, reading MySQL, that POSTs to the Zapier webhook -> QuickBooks. So the ~$360-450 July under-billing finding is unchanged.

USEFUL CONSEQUENCE: the Billing dashboard (Snowflake, complete) and the invoice (MySQL, 3 days missing) will DISAGREE for July 2026. That divergence is the cleanest available proof of the under-billing - screenshot the dashboard's July figure against what was actually invoiced.

SEPARATE DISCREPANCY worth a look: the dashboard's header still advertises a 'Credit Reports: total_apps x $0.30' line item, but PR #5832 (OPS-36, nakula-efp, merged 2026-07-20) 'Remove NorthPond credit pull fees from monthly bill' removed that fee from generate_monthly_fee.py. So the dashboard computes a line item that is no longer billed - dashboard and script have drifted apart on the fee schedule, independent of this ticket.

CONFIRMED AFFECTED (re-verified datasources): 'NorthPond FL 2.0' (uid qWXsxeWDk) is genuinely MySQL - 36 panel targets on mysql datasource Uih1s0PSk, 4 on mysql whibt6c7z, only 1 panel on Snowflake. That dashboard does have the 3-day hole.
- 2026-08-24T20:57Z [claude-code] DIAGNOSIS COMPLETE 2026-08-25. The 25 loans split into TWO distinct causes. Verified in Snowflake PROD.BRONZE.API_EVENTS with controls on every query.

METHOD NOTE (two false results corrected along the way): (1) gateway model_requests/model_responses objects are plain .parquet, NOT .zst+pickle - an earlier scan returned a bogus '0 of 25'. (2) model_requests store the uuid at payload:applicationInformation:applicationUuid while model_responses store it FLAT at payload:application_uuid - a query using only the nested path can never match responses. Correct expression is COALESCE(payload:application_uuid::VARCHAR, payload:applicationInformation:applicationUuid::VARCHAR). Control: 781/781 both event types on 2026-07-03.

COHORT A - 22 loans (requests 2026-07-01 evening through 07-04): correct, matching model_responses exist in S3 and Snowflake. They were simply never loaded into MySQL. The grafana.py backfill DOES fix these.

COHORT B - 3 loans, the ones that were unexplained: 81fe8e12-15c5-46f1-b519-a259e6f97458 (request 2026-07-01 15:50:11 UTC), f430a050-1fe8-49d3-ab32-158320355416 (14:37:12 UTC), f7856925-4f47-4b25-a61f-3a8e3f2b23c0 (14:57:21 UTC). All three applied BEFORE the model redeploy at 19:39 UTC on 2026-07-01. Their responses DO exist but carry a WRONG application_uuid - they are the tail of the ORIGINAL ERROR-1231 bug (NorthPondExpOfferModel minting a fresh uuid instead of passing the applicant's through), which Abhishek fixed by retagging + Jenkins build #62 at 19:39 UTC 07-01. The 07-15 uuid recovery covered the 15 known loans but MISSED these 3.
=> The grafana.py backfill will NOT fix Cohort B: it will load their response rows under the wrong uuid and the reconcile still fails. They need the same uuid recovery, joined on gateway_ns.

JOIN KEY FOR THE RECOVERY: the S3 filename's 19-digit gateway_ns links request<->response. CONTROL 2026-07-05 (post-fix): 553 joined on ns, 553 uuid matches (100%). 2026-06-30 (pre-fix): 712 joined, 0 matches. Recovered mapping for the 3 (real_app_uuid -> uuid_in_response): 81fe8e12->9fb07a54-0f63-400e-954d-32c67069f017 (offer ea2cb7de-8d6a-575f-8cdf-187a7e66b7b9); f430a050->6f06b681-a212-4156-9bdf-2280c9fc13e0 (offer 7b59ced5-9609-5b57-bc71-d4c08a37841b); f7856925->e5061433-5097-4ac1-b2bc-16d368493650 (offer bd79936a-de2c-504d-abcc-f88204e5300e).

BUSINESS FINDING: all 3 responses carry decision=false. EFP DECLINED these three applications and NorthPond funded the loans anyway. That is the genuine 'funded without an EF offer' case Kabeer originally described - worth surfacing to the business separately from the data fix.

EXACT CUTOVER: on 2026-07-01 the no-response count by hour drops to 0 from hour 20:00 UTC onward (hour 19 was 33 of 46), pinning the fix to the 19:39 UTC deploy.

NEW, SEPARATE GAP: the 07-15 recovery was applied to MySQL only. Snowflake bronze.api_events STILL holds the corrupted uuids for the whole pre-fix period - every northpond request from 2026-06-01 to 2026-07-01 19:35 UTC has no joinable response, about 11,595 applications (11,015 in June + 580 on 07-01). Anything joining request->response in the warehouse for that period is broken. Not checked before 2026-06-01, so the true count may be larger. Does NOT affect the Billing dashboard (it counts model_requests only).
- 2026-08-25T14:34Z [claude-code] SNOWFLAKE CORRUPTION SCOPED 2026-08-25 - much narrower impact than feared; effectively nothing to fix in Snowflake.

EXTENT (join on native BRONZE.API_EVENTS.TIMESTAMP_NS + channel + api_version):
 - northpond_loan_fl api_version=1 (2024-04-17 -> 2026-01-15): 276,440 requests, 0 corrupted. CLEAN.
 - northpond_loan_fl api_version=2 (2026-01-16 -> present): 195,800 requests, 21,856 corrupted, window 2026-01-16 -> 2026-07-01.
 - northpond_loan_fl_dark_mode api_version=2 (2025-11-20 -> 2026-01-15): 213 requests, 212 corrupted.
 TOTAL 22,068 responses carrying a wrong application_uuid. First occurrence 2025-11-20 (v2 dark-mode shadow traffic), became the live path at the v2 cutover 2026-01-16, ended 2026-07-01 19:39 UTC with the model retag. Monthly corrupted counts: 2025-11 52, 2025-12 108, 2026-01 95, 2026-02 65, 2026-03 84, 2026-04 228, 2026-05 9844, 2026-06 11012, 2026-07 580, 2026-08 0.

WHY IT DOES NOT NEED FIXING: the silver transform that consumes the affected data, edgefocus/transformations/silver/api_events/northpond_exp_offers.py, joins bronze.api_events on timestamp_ns + channel + platform + api_version (lines 110-121) - NOT on application_uuid. So silver.northpond_exp_offers is correct today and always was. The one northpond transform that DOES join on res.payload:application_uuid is northpond_tu_offers.py:123, and that covers the v1/TU channel which has ZERO corruption (tu_request/tu_raw_data also stop 2026-01-15, before the v2 cutover). No silver table is wrong.

DO NOT MUTATE bronze.api_events: it is a raw mirror of the S3 gateway payloads (the wrong uuid is in the S3 file itself), data_retention_time_in_days=1, and any re-ingest would reintroduce it. Correct posture is to treat timestamp_ns as the canonical request<->response key, which the code already does.
RESIDUAL RISK ONLY: ad-hoc SQL, notebooks or dashboards that join a northpond RESPONSE on payload:application_uuid for 2026-01-16..2026-07-01 will silently return nothing or wrong rows. Worth a note in ~/notes rather than a code change.
- 2026-08-25T15:01Z [claude-code] EXECUTION ATTEMPT 2026-08-25 (Abhishek authorized steps 1-4 on dpx only). Steps 1 and 2 DONE and clean; step 3 BLOCKED, stopped per his standing instruction rather than improvising.

STEP 1 BEFORE-STATE (verified, read-only): MySQL gaps confirmed - 2026-07-01 requests 263/761 responses 154/761; 07-02 0/589; 07-03 0/781; 07-04 0/541. Unreconciled issuance apps: 25 of 1339. Loans 12563327-12563357 present in issued: 5 (07-02 x1, 07-03 x1, 07-06 x1, 07-07 x2).
STEP 2 WRITE GRANT: CONFIRMED. default-writer@'%' holds GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER, CREATE TEMPORARY TABLES, LOCK TABLES ON northpond.* - host-agnostic, so writes from dpx are permitted.

ISOLATION WORK DONE (nothing shared touched): cloned own checkout at ~/claude-ws/error-1231/efp, pinned to true origin/master 99c70e725 (note: a --local clone's origin/master is the SHARED checkout's local master, 5c0005322, which was behind - had to fetch refs/remotes/origin/master explicitly). Confirmed bin/northpond/grafana.py, lib/efp/md_grafana.py, lib/efp/sqlalchemy.py, lib/efp/s3.py are IDENTICAL between the two. IMPORTANT: ~/repos/efp is on branch abhishek/dev-1481-northpond-stmt-dedup-guard with uncommitted changes from another session - his instruction not to work there was correct.

BLOCKER: ~/repos/efp/.venv is an incomplete environment for grafana.py. Missing termcolor (efp.terminal), GitPython (efp.batch), and then mypy_boto3_batch (efp.batch) - a cascade, depth unknown. Installed termcolor 3.3.0 and GitPython into ~/claude-ws/error-1231/pylibs via uv --target (workspace only; the shared .venv is verified still WITHOUT termcolor, deliberately untouched). Stopped at the third missing dep rather than keep patching an environment that prod writes would run from.
Import chain needed: grafana.py -> efp.stats.datastores.northpond.statement_loan_positions -> base_statement_northpond -> base_statement -> efp.batch -> git, mypy_boto3_batch.

NOT a blocker, checked: /efs/data is NOT mounted on dpx, but BaseStatement reads statements from S3 (STATEMENTS_S3_BUCKET='efp-raw'), so add_perf_data() would work from dpx once imports resolve. This matters because add_perf_data() is called INSIDE main()'s per-date loop - if it raised, dates after the first would never process.

TWO CLEAN PATHS (his call): (a) run step 3 on dumbledore where the prod env is complete - the original plan, needs his ssh access; or (b) build a faithful venv in the isolated workspace from the repo's own lockfile, 'cd ~/claude-ws/error-1231/efp && uv sync' (uv is at ~/.local/bin/uv, not on the non-interactive PATH) - uses the project's pinned dependency set rather than hand-picked packages.
NOTHING WRITTEN TO PROD. fix_uuids.py and issued.py untouched as instructed.
