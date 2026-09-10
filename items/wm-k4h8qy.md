---
id: wm-k4h8qy
type: task
title: DEV-1510: NorthPond approved/originated tracking blank on API Gateway Monitoring
status: next
priority: p2
links: [relates:wm-unb6pr]
created: 2026-08-22T08:15:32Z
updated: 2026-09-10T13:03:25Z
source: claude-code
---

Sean Mills filed DEV-1510 (2026-08-05) with no dashboard link: "On the v2 API these
plots (middle and right column) are all blank."

## Dashboard identified (2026-08-22)
PROD **API Gateway Monitoring**, Grafana uid `6bc89871-00e5-4d7b-8e21-cc5513dc2652`,
folder "API Gateway" (/d/6bc89871-00e5-4d7b-8e21-cc5513dc2652/api-gateway-monitoring),
with var platform="North Pond" (northpond), channel=northpond_loan_fl, api_version=2.
Created by sanjali 2026-06-26, last touched kabeer 2026-08-21, v10.

The three columns are panel ids 10/11/12 (stat row, y=19) and 13/14/15 (timeseries,
y=21), x=0/8/16:
  LEFT   Applications Evaluated  = SUM(total_apps_${unit})
  MIDDLE Applications Bid        = SUM(approved_apps_${unit})
  RIGHT  Applications Owned      = SUM(owned_apps_${unit})
all FROM gold.offers_daily WHERE CHANNEL/PLATFORM/API_VERSION = vars.
The geomap trio at y=54 (Evaluated / Bid / Owned by State) mirrors the same three.
Timeseries carry `HAVING SUM(...) > 0`, so an all-zero series renders as an EMPTY
panel, not a flat zero line — that is why Sean sees "blank".

## Root cause: TWO INDEPENDENT BUGS, not one

### MIDDLE column (Applications Bid / Approval Rate) — affects v1 AND v2
prod silver.northpond_exp_offers.DECISION: 173,082 False + 13,867 NULL, ZERO True.
prod silver.northpond_tu_offers.DECISION:  246,769 False,               ZERO True.
DECISION is BOOLEAN, sourced at northpond_{exp,tu}_offers.py:96 as
`res.payload:decision::BOOLEAN`. The gold transforms compare
`decision = TRUE` (offers_daily_utils.py:256/274 -> has_approved_offer), so
approved_apps_count is 0 by construction.
This is KNOWN and documented in-tree — positions.py:110:
  "No DECISION filter here - Northpond's decision field is always False in
   model_responses (it is not a funded-loan signal)."
BUT the gateway DOES compute an approval:
  lib/efp/json_endpoints/platforms/api/northpond/experian/app.py:338
  `approved_df = offers_df[offers_df["decision"] == True]` selects the offers
  actually returned. So the approval signal EXISTS at decision time; it just is
  not what lands in model_responses.payload:decision.
=> Fix is to persist/derive a real approval signal, not to change the comparison.
=> NOTE this is NOT v2-specific. v1 approved is 0 too; Sean only noticed on v2
   because v1 is frozen (last v1 day 2026-01-15).

### RIGHT column (Applications Owned) — v2 ONLY, and it is a one-line stale assumption
northpond_exp_offers_daily.py passes `owned_join_table=""` with the comment
"NorthPond doesn't have purchase tape". That comment is STALE.
northpond_tu_offers_daily.py passes `owned_join_table="silver.northpond_stmt_purchase_tapes"`,
which is why v1 shows 372 owned and v2 shows 0.
prod silver.northpond_stmt_purchase_tapes: 637 rows, 2025-02-05..2026-08-21.
Join test on APPLICATION_UUID: 372 match TU (v1), **265 match EXP (v2)**, 0 match neither.
So wiring the same join into the EXP transform recovers exactly 265 owned
applications, all with tape AS_OF_DATE in 2026-08.
The 265 arrived via DEV-1474 (wm-n7usn7, done) which added the
purchase_file_legacy path. That item's blast-radius list names only
northpond_tu_offers_daily.py / _bucketed.py — the EXP equivalents were not
listed because they never joined the tape. That is the gap.
Also check northpond_exp_offers_bucketed.py for the same omission.

## Supporting prod numbers (2026-08-22, PROD.GOLD.OFFERS_DAILY)
northpond v1 northpond_loan_fl:           2024-04-17..2026-01-15, 246,768 total /      0 approved / 372 owned
northpond v2 northpond_loan_fl:           2026-01-16..2026-08-22, 186,691 total /      0 approved /   0 owned
northpond v2 northpond_loan_fl_dark_mode: 2025-11-20..2026-07-02,     241 total /      0 approved /   0 owned
Cross-platform sanity (last 90d): sofi 553,962/33,458/3,701; upgrade 2,979,666/37,189/1,967;
happymoney 388,066/3,855/123; prosper 55,989/945/27; anchored 8,700/946/36.
northpond is the only high-volume platform with approved=0. openroad is also
approved=0 (39,276/0/0) — likely the same class of bug, separate ticket.

## Cross-link worth noting
The api_version 1->2 cutover in gold.offers_daily is exactly 2026-01-15 -> 2026-01-16,
i.e. a single-day flip. That lines up with Nate's 2026-08-20 account (see
[[wm-unb6pr]]) that TU->Experian was "we literally just flipped the model one day".
So `api_version` on this dashboard is effectively the same v1/v2 TU/Experian split
that DEV-1024 asks for — this dashboard ALREADY has the filter DEV-1024 wants,
just on a different page. Do not conflate the two tickets, but do reference it.

## Recommended action
1. Rewrite DEV-1510's description to name the dashboard + the two distinct causes
   (right now it names no dashboard at all).
2. Ship the RIGHT column first — it is a genuine one-line fix with a known,
   verified payoff (265 apps) and no design decision attached.
3. MIDDLE column needs a product decision: what IS "approved" for NorthPond, given
   model_responses.payload:decision is always False by design. Ask Sean/Nate
   whether "bid" should mean "we returned an offer" (derivable today) rather than
   the unused decision flag.

## Log
- 2026-08-26T12:57Z [claude-code] PR RESERVED 2026-08-22: #6491 (DRAFT) https://github.com/edgefocus/efp/pull/6491, branch abhishek/dev-1510-northpond-approvedoriginated-loan-tracking, base master. Ships the OWNED/originated half only: northpond_exp_offers_daily.py + northpond_exp_offers_bucketed.py now pass owned_join_table='silver.northpond_stmt_purchase_tapes' / owned_join_key='application_uuid', mirroring the TU (v1) siblings. 4 lines, 2 files, no schema change, no shared-code change. Expected effect v2 owned_apps_count 0 -> 265, v1 must stay 372.

BLOCKER: dpx unreachable from ~08:20 UTC (resolves to VPC-internal 172.31.175.73, 100%% packet loss, port 22 closed; grafana.edgefocuspartners.com on public IPs still fine, so it is the VPN tunnel or the instance, not general connectivity). Worked earlier in the same session. Could not use ~/claude-ws; made the change in a blobless clone in the Mac scratchpad instead and pushed from there.

STILL TO DO before it leaves draft (all need dpx):
1. duckdb test over generate_shared_daily_sql — owned rows present with the join, absent without it (no SQL substring assertions).
2. DEV_ABHISHEK run of both transforms + Snowflake before/after with query and result in frame.
3. v1 regression: api_version=1 owned_apps_count unchanged at 372.
Local test run is NOT possible: Mac has system python 3.9.6 and no duckdb; repo targets 3.13 and uses 3.10+ annotation syntax at def time.

NOTE recorded in the PR: neither TU nor EXP declares the purchase tape in source_tables, so a newly landed tape does not itself trigger a re-run — pre-existing v1 behaviour, deliberately not changed here.
- 2026-08-26T19:34Z [claude-code] 2026-08-26 dashboard-harness request (Abhishek): build a scratch Grafana dashboard in the 'Abhishek' folder that copies the prod API Gateway Monitoring panels but reads DEV_ABHISHEK, to eyeball the DEV-1510 fix before it goes near prod. Explicitly disposable — DELETE IT once DEV-1510 is validated.

SCRIPT WRITTEN, NOT YET RUN: scratchpad/make_dev1510_dashboard.py (Mac). GETs prod dash 6bc89871, strips id, sets uid=dev1510-npv2-owned, retitles '[DEV-1510] API Gateway Monitoring - NorthPond v2 owned (DEV_ABHISHEK)', tags dev-1510/scratch/delete-me, rewrites every queryText/rawSql through a new ${database} template var (default DEV_ABHISHEK, switchable to PROD for side-by-side), POSTs into folder uid ffmmyvk05io74f (Abhishek). Has a --delete flag for the teardown. The repoint() regex IS unit-tested offline and is idempotent (bare gold.x and PROD.GOLD.X both handled, already-rewritten strings untouched); nothing else in the script has been executed.

STILL BLOCKED: dpx unreachable all session. Grafana itself IS reachable from the Mac (443 open, public IPs) — the ONLY missing piece for the dashboard is credentials, which live solely in ~/.grafana.env on dpx. So an Editor-scoped Grafana token stored on the Mac would unblock the dashboard half independently of dpx (cf [[wm-jct9pm]], though that one is Viewer scope and a different instance).

VPN DIAGNOSIS: AWS VPN client is running, utun4 is up, and there IS a route to 172.31.175.73 via gateway 10.22.1.1 — but the gateway itself does not answer ICMP and traceroute is silent for 4 hops. So this looks more like the dpx INSTANCE being stopped than the tunnel being down, though AWS Client VPN commonly blocks ICMP to the gateway so it is not conclusive. Abhishek to check the AWS VPN client / whether the instance is running.

NOTE the dashboard alone is not proof: DEV_ABHISHEK gold.offers_daily will not show 265 until the patched transforms are actually RUN there, which also needs dpx.
- 2026-08-26T20:11Z [claude-code] 2026-08-26 VALIDATED IN DEV_ABHISHEK — dpx came back (225d uptime, so it was the VPN tunnel, never the box).

NUMBER CORRECTION: the owned figure is 324, NOT the 265 I logged on 08-22. Not an error in the earlier query — the purchase tape GREW. Tape went 637 -> 696 apps (59 landed 2026-08-22..25), and 265+59 = 324 exactly. Split is still a clean partition: 696 = 372 TU(v1) + 324 EXP(v2) + 0 unmatched. Treat the number as moving daily, not fixed.

PROOF (read-only, transform's own generated SQL, full v2 range 2026-01-16..2026-08-26):
  BEFORE owned_join_table='' : total=230406 approved=0 owned=0   day-rows=225
  AFTER  tape joined         : total=230406 approved=0 owned=324 day-rows=225
total and approved byte-identical; only owned moves. 324 are DISTINCT apps, not double counts — APP_CHANNEL_PAIRS=324, DISTINCT_APPS=324, all in one channel, first_as_of_date 2026-07-29..2026-08-21 all inside the window.

MATERIALIZED: DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 and OFFERS_BUCKETED_DEV1510 = prod rows for everything EXCEPT northpond v2, that slice recomputed from the branch. Deliberately did NOT touch the pre-existing DEV_ABHISHEK.GOLD.OFFERS_DAILY/OFFERS_BUCKETED — another session may own them. Daily and bucketed agree exactly (v1 372 / v2 324 in both), which is the real consistency check since the stat row and the geomap read different tables.

DASHBOARD CREATED: /d/dev1510-npv2-owned 'API Gateway Monitoring - NorthPond v2 owned (DEV_ABHISHEK)', folder Abhishek, tags dev-1510/scratch/delete-me. Copy of prod 6bc89871 with ONLY gold.offers_daily + gold.offers_bucketed repointed (32 queries rewritten); every other table still reads PROD so unrelated panels keep working. Panel sim confirms: panel 12 stat v2 owned=324, panel 15 timeseries 22 non-zero days (so it renders instead of being eaten by HAVING >0), panel 20 geomap FL 92 / MI 43 / VA 35 / GA 34 / TN 22 / OH 18, v1 unchanged 246768/0/372.

TEARDOWN when DEV-1510 closes: python3 /tmp/make_dev1510_dashboard.py --delete on dpx (script also in Mac scratchpad), then DROP the two *_DEV1510 tables.

PR #6491 body rewritten with all of the above. STILL DRAFT — remaining gap is the duckdb unit test over generate_shared_daily_sql; the prod-data proof is stronger but the repo convention wants an executable test. Workspace is ~/claude-ws/dev-1510/efp (isolated clone, not ~/repos).

STILL UNFIXED and called out in the PR: Applications Bid = 0 on BOTH v1 and v2. Confirmed again in the materialized tables. That is the decision-half of DEV-1510.
- 2026-08-26T20:24Z [claude-code] 2026-08-26 DASHBOARD REBUILT LEAN (Abhishek: 'I wasn't expecting you to copy the entire dashboard... only the panels Sean was mentioning'). v1 of the scratch dash was a full 25-panel clone; replaced with v2 carrying ONLY Sean's three-column block — panels 10/11/12 (stats) + 13/14/15 (timeseries) = Evaluated / Bid / Owned, plus a markdown note panel explaining what to look at. Template vars trimmed 6 -> 4 (platform, channel, api_version, unit); breakdown/averages dropped as unused. 6 queries repointed (was 32). Same uid dev1510-npv2-owned so the link is stable; new slug /d/dev1510-npv2-owned/59a7b4c.

ORIGINAL CONFIRMED UNTOUCHED, checked twice: prod 6bc89871 still v10, updated 2026-08-21 by kabeer, 25 panels, 0 DEV_ABHISHEK refs, still reads gold.offers_daily. The script only ever GETs it and POSTs to its own uid — there is no write path to the original in the code.

Consequence of going lean: the dashboard no longer reads OFFERS_BUCKETED_DEV1510 (the geomaps were dropped). That table still stands and the bucketed half of the fix is still proven by SQL (v1 372 / v2 324 under BUCKET_NAME=STATE, agreeing exactly with daily). Teardown should still drop BOTH *_DEV1510 tables.

STANDING PREFERENCE TO CARRY FORWARD: when building a scratch/verification dashboard, replicate only the specific panels in question — do not clone a whole dashboard.
- 2026-08-26T20:27Z [claude-code] 2026-08-26 SCRATCH DASHBOARD WAS BROKEN — my bugs, four of them, now fixed (dash v2 -> v4). Abhishek opened it and saw nothing working.

ROOT CAUSE 1 (the one he actually saw): I carried the prod dashboard's SAVED VARIABLE STATE over verbatim, which points at platform=openroad / channel=openroad_auto_refi / api_version=1. OpenRoad has approved=0 AND owned=0 in these tables, so all three stat panels read 0 and both lower timeseries were eliminated by their own 'HAVING SUM(...) > 0'. The dashboard therefore opened completely empty on a slice that has nothing to do with NorthPond. Fixed by forcing current= northpond / northpond_loan_fl / 2 / count.

ROOT CAUSE 2: template-variable SQL was never repointed. My rewriter only touched keys named queryText/rawSql, but query-type Grafana variables keep their SQL under the key 'query'. So the channel and api_version dropdowns were still reading PROD.GOLD.OFFERS_DAILY while the panels read the DEV table. Fixed by adding 'query' to the rewrite key set (safe: custom vars store an options string there, which the table regexes never match). Repointed count went 6 -> 8.

ROOT CAUSE 3: I hand-built the dashboard dict and omitted annotations/editable/timepicker/graphTooltip/fiscalYearStartMonth/weekStart/links. editable defaulted to FALSE, so he could not even adjust it in place. All now carried over from the source.

ROOT CAUSE 4 (would have bitten next): default window was 12 months, but v1 ended 2026-01-15 — at 12M v1 shows owned=0 (evaluated only 7,684). Flipping to v1 to compare would have read as 'still broken'. Verified across windows: v1 owned = 0 (12M) / 370 (2y) / 372 (3y); v2 owned = 324 at every window. Default now now-3y so both versions are fully in frame.

VERIFIED by running the dashboard's own SQL: channel var -> northpond_loan_fl + northpond_loan_fl_dark_mode; api_version var -> 1, 2; stats at the new defaults -> evaluated 230,399 / bid 0 / owned 324.

LESSON: when lifting panels into a scratch dashboard, the saved template-variable state comes with them and will point wherever the source was last left. Always pin current= explicitly to the slice under test, and re-run the variable queries themselves — not just the panel queries — before calling it done.
- 2026-08-27T12:57Z [claude-code] 2026-08-26 DASHBOARD REBUILT FROM SCRATCH (3rd attempt). Abhishek: 'still broken — and the problem is that it's still a copy of the prod dashboard rather than what I asked for.' Correct: v2-v4 were all derived from prod 6bc89871 by GET + rewrite, which is why prod's baggage (saved variable state, unused vars, HAVING>0, prod-pointed var queries) kept leaking through. v5 is AUTHORED, and the build script no longer reads 6bc89871 at all.

SHAPE: 6 data panels + 1 markdown note. Stats row (ids 100/101/102) and timeseries row (200/201/202) = Evaluated / Bid / Owned. Exactly ONE variable, api_version, a CUSTOM var with options 1,2 (no query, so nothing to point at the wrong database). platform='northpond' and channel='northpond_loan_fl' are INLINED in all 6 queries — no selectors. Table is DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 in every query. Default time 2024-04-01 -> now (absolute, so v1 which ends 2026-01-15 is always in frame). Dropped HAVING SUM(...)>0 deliberately: a real zero now draws a flat line instead of an empty panel, which is the whole point when Bid is legitimately 0.

VERIFICATION IS NOW READ-BACK, not trust-the-rewriter: the script GETs the deployed dashboard and asserts (a) every queryText contains the DEV_ABHISHEK table, (b) every queryText contains the hardcoded platform and channel literals, (c) templating list == exactly ['api_version'], (d) zero 'PROD.' references after masking DEV_ABHISHEK, (e) no leftover $platform/$channel refs. Exits non-zero on any failure. All PASS at v5.

DATA CONFIRMED for both versions at the dashboard's own default window: v1 = 246,768 / 0 / 372 over 521 day-points (180 with owned>0); v2 = 230,399 / 0 / 324 over 218 day-points (22 with owned>0). Both render.

PROD UNTOUCHED (checked again after): 6bc89871 still v10, 2026-08-21 by kabeer, 25 panels, 0 DEV_ABHISHEK refs.

OPEN DEVIATION TO RESOLVE WITH HIM: he asked for the dashboard to read 'the same tables the job writes, in DEV_ABHISHEK' — that would be DEV_ABHISHEK.GOLD.OFFERS_DAILY, not my *_DEV1510 suffixed copy. I used the suffix to avoid clobbering the pre-existing DEV_ABHISHEK.GOLD.OFFERS_DAILY (10,429 rows) which another parallel session may own. Schema and the northpond slice are identical, so the answer is the same, but the table NAME differs from the job's real target. Needs his call: overwrite the real table or keep the suffix.
- 2026-08-27T13:14Z [claude-code] 2026-08-27 'No data' everywhere — TWO real causes, both of which my earlier verification was structurally incapable of catching. I had been running the panel SQL myself through sqlrun (user abhishek, role DB_CREATOR) and calling that verified. Grafana does not run queries as me.

CAUSE 1 — MISSING queryType ON THE TARGETS. I hand-authored the panel targets with only {refId, datasource, queryText}. The michelin-snowflake-datasource plugin requires queryType ('table' for stat panels, 'time series' for timeseries), plus fillMode and timeColumns. Without queryType the plugin returns no frames at all -> every panel renders 'No data'. Found by diffing my target JSON against prod panels 12/15. Fixed.

CAUSE 2 — NO SELECT GRANT FOR THE GRAFANA ROLE ON DEV_ABHISHEK. The Grafana Snowflake datasource (uid bqzSrsZvz, the ONLY Snowflake datasource) connects as user GRAFANA_USER / role GRAFANA_READER / warehouse COMPUTE_WH_XS_GRAFANA. That role could not read ANY table in DEV_ABHISHEK — not my scratch tables, not the pre-existing DEV_ABHISHEK.GOLD.OFFERS_DAILY either. Error: 'Object ... does not exist or not authorized.'
Diagnosis by comparison: GRAFANA_READER CAN read DEV_KABEER.GOLD.OFFERS_DAILY (8,727 rows) and DEV_SCOTT.GOLD.OFFERS_DAILY (10,361). Grants tell the story — USAGE on database and schema is already granted to GRAFANA_READER on DEV_ABHISHEK, but TABLE-level SELECT is not, and there are NO future grants on any of these schemas. Kabeer's table carries an explicit 'SELECT -> GRAFANA_READER'; Abhishek's carries only OWNERSHIP -> DB_CREATOR. So every dev table needs an explicit grant, one at a time.

ACTION TAKEN (tell him, it is a privilege change on his own dev DB):
  GRANT SELECT ON TABLE DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 TO ROLE GRAFANA_READER;
  GRANT SELECT ON TABLE DEV_ABHISHEK.GOLD.OFFERS_BUCKETED_DEV1510 TO ROLE GRAFANA_READER;
Scoped to the two scratch tables only — deliberately NOT 'ALL TABLES' and NOT 'FUTURE TABLES', so nothing else in his dev database becomes Grafana-readable. Revoke with REVOKE SELECT ON TABLE ... FROM ROLE GRAFANA_READER.
GENERAL CONSEQUENCE worth remembering: any future DEV_ABHISHEK-backed Grafana dashboard will hit this same wall until the table is granted. Consider asking whether he wants a one-time 'GRANT SELECT ON FUTURE TABLES IN SCHEMA DEV_ABHISHEK.GOLD TO ROLE GRAFANA_READER' so this stops recurring.

VERIFIED PROPERLY THIS TIME via POST /api/ds/query — Grafana's own execution path, not mine. All 12 panel/version combinations return data:
  v1: evaluated 246,768 (521 day-points) / bid 0 / owned 372
  v2: evaluated 230,399 (218 day-points) / bid 0 / owned 324
Also confirmed the frame schema: AS_OF_DATE comes back type=time / time.Time, identical to prod reference panel 13 — so the timeseries panels genuinely plot rather than just returning rows. New script ~/claude-ws/dev-1510/bin/ds_check.py does this and exits non-zero on any failure; it is the check to run before ever telling him a dashboard works.
- 2026-08-31T15:50Z [claude-code] SWEEP 2026-08-31 — PR #6491 ('DEV-1510: Wire NorthPond EXP (v2) offers to the purchase tape for owned-app counts') has not moved in five days: OPEN, **isDraft=true**, zero reviewers requested, zero reviews, last update 2026-08-26T20:10Z. Linear DEV-1510 is 'In Progress'.

The v5 scratch dashboard rebuild and the DEV_ABHISHEK validation both landed on 08-26/08-27 per the entries above, so the blocking work is behind us — what is left is that the PR is invisible. Same failure mode as [[wm-xe6w4q]]: draft + no reviewer means no review is coming.

Still outstanding from this item's own history and NOT done: the scratch Grafana dashboard in the 'Abhishek' folder (uid dev1510-npv2-owned) was explicitly created as disposable and is to be DELETED once DEV-1510 is validated. It is still there.
- 2026-08-31T19:32Z [claude-code] 2026-09-01 'still completely broken'. Checked current state first: dashboard intact at v6 (untouched since 08-27), tables and grant still in place, and ds_check still PASSES all 12 panel/version combos. So the query path was never the remaining problem.

CORRECTION TO AN EARLIER ASSUMPTION: I previously wrote that Grafana's GRAFANA_USER was a service account distinct from Abhishek. WRONG — ~/.grafana.env authenticates as login=abhishek, abhishek@edgefocuspartners.com, Editor in org 1 (the single org). So my /api/ds/query checks were already running as HIS Grafana identity. GRAFANA_USER is separately the SNOWFLAKE username in the datasource jsonData (keyPair auth, warehouse COMPUTE_WH_XS_GRAFANA) — two different things that share a name. Not a permissions/identity problem.

NEW CAUSE FOUND — SCHEMA VERSION MISMATCH. Grafana is 12.3.1 and its own dashboards carry schemaVersion 42. I hand-authored mine with schemaVersion 39 and no pluginVersion on any panel. Grafana's frontend runs migrations from the declared schemaVersion up to current, so it was migrating my panels on every load — which rewrites stat/timeseries option shapes and can leave panels rendering broken even though /api/ds/query returns perfect frames. That is exactly the signature here: API fine, UI broken.

FIX (dash v7): schemaVersion 39 -> 42; every panel now carries pluginVersion 12.3.1; and the panel option/fieldConfig SHAPE is taken from panels this Grafana already renders correctly (prod panels 12 and 13) with id/title/gridPos/targets/description all replaced by ours. So nothing of prod's content is copied — only the Grafana-12 option schema — and the frontend has nothing left to migrate. ds_check still passes 12/12 after the change.

NOT YET CONFIRMED BY HIM. Three prior 'fixed' claims were wrong, so this one is a hypothesis with a mechanism, not a verified fix. I still do not know the actual symptom he sees — 'No data' in panels vs an error banner vs panels failing to render vs the dashboard not loading. ASK FOR THE SPECIFIC SYMPTOM AND A SCREENSHOT before iterating again; continuing to guess has now cost him four rounds.
- 2026-08-31T19:44Z [claude-code] 2026-09-01 PR #6491 brought up to date for review.

NUMBERS MOVED AGAIN (as predicted — this is a daily-growing count, not a fixed one): purchase tape 696 -> 797 apps, and v2 owned 324 -> 425. Partition still perfectly clean: 797 = 372 TU(v1) + 425 EXP(v2) + 0 unmatched. v1 stays 372 throughout. The PR description now states the INVARIANT (every tape app matching a v2 offer should count as owned) with a dated snapshot, rather than presenting a moving number as fixed.

Re-ran everything with current data: BEFORE total=275608/approved=0/owned=0, AFTER total=275608/approved=0/owned=425 over 230 day-rows. total and approved unchanged, only owned moves.

BRANCH: merged origin/master in (NOT a rebase — avoids a force-push on a branch others could touch). Was 55 behind, now 0. Diff vs master is still exactly the 4 lines in 2 files. Pushed d74b7e2 -> 1652afd.

GOTCHA WORTH REMEMBERING: refreshing the scratch tables uses CREATE OR REPLACE, which DROPS the Snowflake grants. The dashboard would have silently gone back to 'not authorized' if I had not re-granted SELECT to GRAFANA_READER straight after. Any future refresh of DEV_ABHISHEK.GOLD.*_DEV1510 must re-run ~/claude-ws/dev-1510/bin/grant.sql. Re-verified after: ds_check passes 12/12, v2 owned now reads 425 in Grafana.

DESCRIPTION STYLE FEEDBACK (2026-09-01): my rewrite was too long. He wants PR descriptions kept very small — 2-3 bullets on what changed, then a short validation section with just the runs actually performed, and NO 'Notes for review' section and no mention of CI/test success. Trimmed accordingly. Recorded as a standing preference; see also ~/pr-style.md.

STATE: still draft (he marks it ready himself), mergeable, mergeStateStatus BLOCKED only because REVIEW_REQUIRED with zero reviewers. Run Tests re-running on the new head. Remaining optional gap: no duckdb unit test over the owned join.
- 2026-09-01T17:46Z [claude-code] 2026-09-01 PR #6491 description: added collapsible <details> sections carrying the SQL behind each number, per his ask ('I do not see a collapsible section wherein we show the SQL which shows whatever output we have or the table we have'). Two collapsibles only, top bullets left short: (1) 'The CTE that changes' — the WHERE 1=0 empty owned set vs the real INNER JOIN on the purchase tape, plus why MIN(as_of_date) prevents counting an app on every day it appears; (2) 'Query behind that table' — the DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 SELECT with its verbatim output, and the matching OFFERS_BUCKETED_DEV1510 result showing daily and by-bucket agree.

COURSE CORRECTION: I had started re-materializing the scratch tables because the tape had grown AGAIN within the hour (797 -> 823 apps, v2 match 425 -> 451) and the gold snapshot no longer matched a freshly-run tape query. He stopped me — 'We need not modify everything. I just need to have the query attached in the description.' Right call: chasing a number that moves hourly is pointless churn. Resolved instead by only attaching the query that backs the table actually shown (the gold read, self-consistent at 372/425), omitting the tape-partition query whose live result would have contradicted it, and stating in the collapsible that owned grows as purchases land so the figures are a snapshot with the invariant being 'owned == tape apps matching v2 offers, none unmatched'.

LESSON: when a validation number drifts between runs, do not re-run everything to make it agree. Publish one internally-consistent snapshot, name the timestamp, and state the invariant rather than the count.

NOT re-materialized, NOT re-granted — DEV_ABHISHEK scratch tables and the dashboard remain as they were at 2026-09-01 ~10:0x (v2 owned 425). Still draft; he flips it to ready himself.
- 2026-09-01T18:25Z [claude-code] 2026-09-01 PR #6491 MERGED (958912c4df, merged by abhishek-edgefocus 17:50Z). Owned/originated half of DEV-1510 is now on master.

NEXT AND CRITICAL: merging changes NOTHING in prod until the two gold assets are re-run over the v2 range. They are stream-driven (StreamSource on silver.northpond_exp_offers with watermarks), so a normal tick only processes new data — history stays at owned=0 until an explicit dated backfill.

BACKFILL HANDOVER (his run, not mine — no agent prod runs). Dagster assets northpond_exp_offers_daily and northpond_exp_offers_bucketed, both group GOLD, both in job ingest_api_output, dep northpond_exp_offers. Config schema is TransformConfig (orchestration/assets/common/asset_factories.py:19): as_of_date str default '' (incremental), accepts 'all', a single YYYY-MM-DD, or a RANGE 'YYYY-MM-DD:YYYY-MM-DD' (range parsing at edgefocus/data_warehouse/snowflake.py:905); warehouse str default COMPUTE_WH_XS_PROD. So the run config per asset is as_of_date: '2026-01-16:<today>' — 2026-01-16 is the first v2 day in gold.offers_daily. Run daily and bucketed both; the by-state geomap comes from bucketed.

REMAINING WORK ON DEV-1510 (the ticket is only PARTIALLY addressed):
1. Applications Bid still 0 on BOTH v1 and v2 — model_responses.payload:decision is False for every NorthPond offer by design. Needs a product decision from Sean/Nate on what 'bid' should mean (candidate: 'we returned an offer', derivable today) before any code. Should probably be split into its own ticket.
2. OpenRoad shows the identical approved=0 pattern (39,276 evaluated / 0 approved / 0 owned) and has no ticket.
3. No duckdb unit test over the owned join was ever added — merged without one.

TEARDOWN, deliberately NOT done yet: keep the scratch dashboard /d/dev1510-npv2-owned and DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 / OFFERS_BUCKETED_DEV1510 until the PROD backfill is run and prod API Gateway Monitoring is confirmed showing owned for v2. They are the before-picture to compare against. Then: python3 ~/claude-ws/dev-1510/bin/make_dev1510_dashboard.py --delete, DROP both *_DEV1510 tables, and REVOKE SELECT ... FROM ROLE GRAFANA_READER.
- 2026-09-01T18:31Z [claude-code] 2026-09-02 BACKFILL CONFIG CORRECTED — he asked 'should we not simply do as of date all?' He is right; my hand-computed range 2026-01-16:2026-09-01 was wrong and I should not have offered it.

WHY THE RANGE WAS WRONG. silver.northpond_exp_offers spans 2025-11-20 -> 2026-09-01 across TWO channels, not one:
  northpond_loan_fl           2026-01-16..2026-09-01  286,787 rows    0 before 2026-01-16
  northpond_loan_fl_dark_mode 2025-11-20..2026-07-02      256 rows  238 before 2026-01-16
I derived 2026-01-16 from the loan_fl channel alone and forgot dark_mode entirely, so 238 rows of dark-mode dates would never have been reprocessed and that channel would have kept the pre-fix shape indefinitely.

SUBTLER TRAP, worth remembering for ANY backfill of this transform family: owned_application_ids has NO date filter (it scans the whole source), but the outer join is ald.as_of_date = owned.first_as_of_date, and ald IS date-filtered. So an application whose GLOBAL first appearance falls outside the processed window is silently never counted as owned — a narrow window bakes in a permanent blind spot rather than merely deferring work. Today: 451 owned pairs, earliest first_as_of_date 2026-07-29, so 0 would actually have been missed — but that is a today-fact, not a guarantee, and it would not have shown up as an error.

SAFETY OF 'all' VERIFIED IN CODE (transform.py on master): every DELETE is built as key_column IN (<dates>) AND target_table_where_clause, and for these two assets that clause is platform='northpond' AND api_version=2. So 'all' structurally cannot touch other platforms in the shared gold tables. Watermarks still advance correctly in all-mode (it explicitly fetches run_max_ts when none was captured). reload_subsequent floor tracking is skipped on explicit runs by design ('user controls the key set'). Precedent: the openroad_offers backfill used as_of_date: all (see [[wm-85nuv4]]).

FINAL HANDOVER: assets northpond_exp_offers_daily and northpond_exp_offers_bucketed, materialized INDIVIDUALLY (never the whole ingest_api_output job — that would rebuild all 14 platforms incl. upgrade's ~735M model_requests rows), config as_of_date: all, warehouse COMPUTE_WH_XS_PROD. 287,043 source rows total, trivial on XS. Deploy already confirmed live: deploy-dagster-prod succeeded 2026-09-01T17:54:29Z on sha 958912c4, the merge commit — and that workflow is workflow_dispatch only, never automatic on merge, so it always needs checking before a backfill.
- 2026-09-01T18:36Z [claude-code] 2026-09-01 PROD BACKFILL, part 1 of 2 — northpond_exp_offers_daily DONE.
Run 4d9d9896-978b-4ae8-87fb-054ba2d4a928, job __ASSET_JOB scoped to the single asset, config as_of_date: all / COMPUTE_WH_XS_PROD. SUCCESS in 0.33 min (20s), 1 step, 1 materialization.

PROD.GOLD.OFFERS_DAILY northpond after the run:
  v1 northpond_loan_fl            246,768 / bid 0 / owned 372   2024-04-17..2026-01-15  521 days  (UNCHANGED — regression guard holds)
  v2 northpond_loan_fl            286,785 / bid 0 / owned 451   2026-01-16..2026-09-01  224 days  (owned was 0)
  v2 northpond_loan_fl_dark_mode      241 / bid 0 / owned   0   2025-11-20..2026-07-02   63 days
Cross-platform sanity, last 90d: no other platform moved (sofi 3,771 owned, upgrade 2,679, happymoney 130, prosper 54, foursight 91, anchored 35, revolut 0, openroad 0). The target_table_where_clause scoping held as predicted.

DARK_MODE owned=0 IS CORRECT, NOT A GAP — verified rather than assumed: all 451 tape-matched v2 applications sit in northpond_loan_fl, and of the 234 distinct dark_mode applications, ZERO appear in silver.northpond_stmt_purchase_tapes. Dark mode is shadow traffic that is never purchased, so 0 owned is the right answer. Running as_of_date: all still mattered — it reprocessed those 63 dates (back to 2025-11-20) under the new code instead of leaving them on the old shape.

STILL TO RUN: northpond_exp_offers_bucketed, same config (as_of_date: all, COMPUTE_WH_XS_PROD), materialized individually. Confirmed still stale — PROD.GOLD.OFFERS_BUCKETED BUCKET_NAME=STATE currently reads v1 372 / v2 0 / dark_mode 0. Until it runs, Applications Owned by State stays blank on the prod dashboard while the stat row and timeseries are already correct.
- 2026-09-01T18:40Z [claude-code] 2026-09-01 PROD BACKFILL COMPLETE — DEV-1510 owned half is live.
Run 0bec3638-c995-4cb0-968a-2d7dbeb61829 (northpond_exp_offers_bucketed, as_of_date: all, XS) SUCCESS in 0.31 min. Both assets now done.

PROD.GOLD.OFFERS_BUCKETED (STATE) after: v1 loan_fl 372, v2 loan_fl 451, v2 dark_mode 0.
DAILY vs BUCKETED AGREE on all three (version, channel) pairs — 372/372, 451/451, 0/0. That is the check that matters, since the stat row and the geomap are computed from different tables.
Owned by state, v2: FL 119, GA 57, MI 57, VA 52, OH 29, TN 27, MO 19, KY 19.
Cross-platform sanity on bucketed STATE, 90d: unchanged (sofi 3,771, happymoney 131, foursight 91, prosper 54, anchored 35, openroad 0, revolut 0, lendingclub 0).

PROD DASHBOARD VERIFIED through /api/ds/query (not just SQL), platform=northpond channel=northpond_loan_fl:
  v2 stat Owned 451, geomap Owned/State 15 states, ts Owned 29 day-points. v1 unchanged 372 / 11 states / 180 points.

CORRECTION TO MY OWN EARLIER CLAIM — OWN RATE WILL NOT COME BACK. I told him this fix would restore 'Applications Owned, Look to Book, Own Rate and Owned by State'. Wrong on Own Rate. Panel 9 is SUM(owned_apps)/NULLIF(SUM(approved_apps),0) — the denominator is approved, which is 0 for every NorthPond row, so every value is NULL and the panel stays empty regardless of owned. It is gated on the BID half, not the owned half. Verified by reading the panel SQL.
What each panel does now on v2:
  Applications Owned (stat/ts/geomap) — WORKING, 451
  Look to Book = owned/total                — WORKING (denominator is total, not approved)
  Own Rate = owned/approved                 — STILL BLANK, blocked by the bid half
  Applications Bid / Approval Rate          — STILL 0/blank, the unfixed half (Approval Rate also carries HAVING SUM(approved)>0, so it returns zero rows)
Note the ts panels carry HAVING SUM(owned)>0, so 29 day-points for v2 means 29 days with a purchase — correct, not a gap.

REMAINING: teardown (scratch dashboard /d/dev1510-npv2-owned, DROP the two *_DEV1510 tables, REVOKE SELECT FROM ROLE GRAFANA_READER) — deliberately held until he confirms prod looks right. Then DEV-1510 ticket state: owned half done, bid half needs its own ticket + a product decision from Sean/Nate. OpenRoad has the identical approved=0 pattern and is still unticketed.
- 2026-09-02T18:13Z [claude-code] 2026-09-02 FALSE-ALARM CHECK — an alert claimed 'northpond: zero approved offers for 14+ consecutive days (2026-08-18..2026-09-01), business/credit-policy signal, may be an unintentional program pause.' REFUTED against PROD.GOLD.OFFERS_DAILY today.

The 14 days is an artifact of the alert's lookback window. approved_apps_count has been 0 on ALL 809 northpond day-rows since 2024-04-17 — v1 loan_fl 246,768/0/372 (2024-04-17..2026-01-15), v2 loan_fl 296,383/0/451 (2026-01-16..2026-09-02), v2 dark_mode 241/0/0. max(approved_apps_count) over the whole platform history = 0. So ~869 days, not 14, and it predates the v1->v2 cutover, which no credit-policy change would.

Root cause is the unfixed BID half of this ticket, re-confirmed live: silver.northpond_exp_offers.DECISION = 273,286 False + 23,355 NULL, ZERO True; northpond_tu_offers.DECISION = 246,769 False, ZERO True. gold's has_approved_offer compares decision = TRUE, so approved is 0 by construction.

Two independent disproofs of the 'credit box closed' reading: (1) openroad shows the identical 38,924 evaluated / 0 approved / 0 owned pattern in the same 90d window — same class of bug, not a NorthPond business event; (2) owned_apps_count is NON-ZERO across the exact window the alert flags (37 apps owned on 2026-08-18, 32 on 08-19, 26 on 08-20 ...), i.e. loans were being APPROVED AND PURCHASED on the very days the alert calls zero-approval. The 0s in owned from 2026-08-29 are purchase-tape lag, not a stop.

The alert's one correct fact: total apps on 2026-09-01 = 11,698, matches exactly.

TAKEAWAY FOR THE TICKET: this is the first time the bid-half bug has generated a downstream false alarm rather than just a blank panel. Worth citing when splitting the bid half into its own ticket — a metric that is 0 by construction will keep being read as a business signal by anything that watches it.
- 2026-09-08T18:48Z [claude-code] 2026-09-09 Abhishek revisited the dashboard and asked why the Bid charts are still blank for NorthPond, hunching that it is because 'we do not really provide offers, we just provide a score to Oliv and they calculate offers at their end'. THAT HUNCH IS WRONG, and it matters for how the bid half gets specified.

EVIDENCE (read-only, prod, last 7 days). bronze.api_events model_responses for northpond carry a full PRICED OFFER, not a bare score: top-level payload keys include offer_uuid, apr, rate, credit_grade, priority, internal_fund_name, gateway_transaction_id, plus 36 monthly efp_default_monthly_N and full_prepay_monthly_N curves. 68,669 responses in 7 days, and decision is literally false on ALL 68,669.

silver.northpond_exp_offers, same window: 74,036 rows, exactly ONE offer per application (74,036 apps, all offers_per_app=1). APR present on 68,669 (92.7%), credit_grade on 68,679, ANL on 68,392. Only 157 rows carry error_messages, and those are all Experian credit-pull INFRASTRUCTURE failures (HTTP 400 no credit profile, Experian read timeouts, connection aborted) — not credit declines.

So the ~5,367 applications with no APR are NOT explained by errors (only 157) — roughly 5,210 got neither a price nor an error. Those are plausibly genuine knockouts/declines, i.e. exactly the population a real 'bid' metric would exclude. Priced-vs-unpriced is therefore a usable, already-present signal: ~93% bid rate on the last 7 days. This strengthens the earlier candidate definition ('we returned an offer') from a guess to something with a concrete split in the data — but the 5,210 have NOT been characterised yet, so confirm what they are before specifying the metric.

RESTATED CAUSE for the blank panels: approved_apps_count counts applications where decision = TRUE (offers_daily_utils.py:256/274). decision is false on 100% of NorthPond rows on BOTH api versions (v1 TU 246,769 all false; v2 exp 173,082 false + 13,867 null), so the count is 0 by construction. Documented in-tree at northpond/positions.py:110 — the decision field 'is not a funded-loan signal'. Knock-on: Approval Rate carries HAVING SUM(approved)>0 so it returns zero rows, and Own Rate is owned/NULLIF(approved,0) so every value is NULL — both blank for reasons that have nothing to do with the owned fix that shipped.
- 2026-09-09T18:12Z [claude-code] 2026-09-09 CORRECTION TO MY OWN 2026-09-09 ENTRY — I logged 'THAT HUNCH IS WRONG'. It was MY reading that was wrong. Abhishek is right: on v2 we do NOT bid, we return a credit grade only.

WHERE I WENT WRONG: I read offer_uuid / apr / rate / credit_grade / priority off bronze.api_events EVENT_TYPE='model_responses' and concluded we return priced offers. model_responses is our INTERNAL model output event. What we actually send Oliv is endpoint_transactions payload:response, and that is a different, much smaller object.

WHAT WE ACTUALLY RETURN (v2, endpoint_transactions payload:response, 30 days):
  timestamp 280,589 | requestUuid 280,589 | applicationUuid 279,851 | experianMissingFeatures 276,716 | creditGrade 276,716 | errorMessages 738
  There is NO offers key. Zero occurrences in 30 days. No apr, no rate, no term.
v1 (TU, legacy) BY CONTRAST: offers present on 246,769 events, array size exactly 1 each (plus 29,727 with no offers key). So v1 DID bid, one offer per application.
upgrade, a genuine bidding platform, for contrast: offers, adverseActionReasons, modelName, policyVersion, testCell.
=> The v1->v2 cutover changed us from an offer-returning API to a grade-returning API. 'Applications Bid' is meaningful for v1 and conceptually inapplicable to v2.

THE ~5,091/week UNPRICED COHORT ARE NOT DECLINES OR KNOCKOUTS. Two concrete responses, same shape:
  PRICED   {applicationUuid, creditGrade: 28, experianMissingFeatures: null, requestUuid, timestamp}
  UNPRICED {applicationUuid, creditGrade: null, experianMissingFeatures: {creditReport: [p13_alj8120, p13_all0437, ... dozens of attributes]}, requestUuid, timestamp}
So no grade is produced because the EXPERIAN CREDIT-REPORT FEATURES ARE MISSING — a data-availability failure, not a credit decision. result=SUCCESS on all of them. Of 2,369 such events in 3 days only 342 have any model_response at all, so ~86% never reached the model. Split of the cohort: 2,024 missing-features / 56 Experian pull errors (HTTP 400, read timeouts). Steady 7-9% of daily volume, single channel northpond_loan_fl, no date burst. Directly related to [[wm-ufw7kj]] (DEV-1490 missing Clarity/Experian attributes).

CONSEQUENCE FOR SEAN / DEV-1510: the bid half is a DEFINITION change, not a fix. On v2 the honest funnel is Evaluated -> Graded -> Owned. 'Applications Bid' should be retired or redefined as 'Graded' (creditGrade non-null), which is already derivable with no upstream change. The ungraded ~7-9% is arguably the more useful middle column — it is a live Experian data-quality signal, not lost business.

CAVEAT NOT YET CLOSED: this is all from endpoint_transactions. If Oliv receives pricing through some other channel or a later call, this would not show it. The v1-vs-v2 contrast within the same event type is strong but worth one sentence of confirmation from Nate.
- 2026-09-09T18:35Z [claude-code] 2026-09-10 Own Rate panel confirmed blank, verified through /api/ds/query rather than restated. It is NOT a separate bug and NOT something the owned backfill could have fixed.

Panel 9 Own Rate = SUM(owned_apps)/NULLIF(SUM(approved_apps),0). approved is 0 for northpond, so NULLIF(0,0) makes the denominator NULL and every row divides to NULL.
Measured: v1 returns 180 rows / 0 non-null; v2 returns 30 rows / 0 non-null. First values literally [None, None, None, None, None]. So Grafana receives rows but has nothing to plot — the panel draws empty rather than erroring.
DISTINCT FAILURE MODE from the Bid panels, worth keeping straight: Applications Bid returns rows with the value 0; Approval Rate returns ZERO rows (it carries HAVING SUM(approved)>0); Own Rate returns rows whose values are all NULL. Three different-looking blanks, one root cause.

Look to Book, by contrast, WORKS on both versions — 180/180 and 30/30 non-null (v2 first values 0.000894, 0.000461, 0.000544...). Because its denominator is total_apps, not approved.

AFFECTS V1 TOO, which sharpens the story: on v1 we genuinely did bid (one offer per application, 246,769 of them), yet Own Rate has never worked there either, because decision was never TRUE on any TU row. So Own Rate has been blank for NorthPond for its entire history on both APIs.

FOR SEAN: Own Rate is defined as owned/bid. If 'bid' is not a meaningful concept for NorthPond v2 (we return a grade, Oliv prices), then Own Rate inherits that and is equally meaningless — it should be retired for this platform alongside Applications Bid, not fixed. The working analogue already on the dashboard is Look to Book (owned/evaluated). If a conversion rate off the scored population is wanted, owned/graded is the v2-appropriate definition and is derivable today.
- 2026-09-09T18:45Z [claude-code] 2026-09-10 'Days from Offer to Purchase-Tape Date' and 'Days from Offer to Funding' (panels 53, 54) — blank for a DIFFERENT reason than the Bid/Own Rate family, and NOT because we do not provide an offer.

CAUSE: northpond has ZERO rows in PROD.GOLD.FUNDING_LAG. The platform is simply absent from the table. Present: upgrade 16,502 / sofi 8,525 / anchored 356 / prosper 303 / happymoney 82 / foursight 81. northpond 0.
Root of that: there is no NorthpondFundingLag transform. edgefocus/transformations/gold/funding_lag.py defines exactly six subclasses — Upgrade, Sofi, Prosper, Happymoney, Anchored, Foursight — and the funding_lag assets are registered in those six platforms' asset files only.  on master returns NOTHING. It was never built for this platform.
Note both panels filter on platform only, no api_version and no channel, so flipping the api_version selector has no effect on them.

HIS HYPOTHESIS (blank because we do not provide an offer) DOES NOT HOLD, and the metric is fully computable today. Proved it in prod: joining silver.northpond_stmt_purchase_tapes to MIN(as_of_date) per application in silver.northpond_exp_offers gives 646 owned applications, ALL 646 with a computable lag. Min 2 days, median 4, max 18. Histogram: 2d=116, 3d=114, 4d=155, 5d=160, 6d=43, 7d=15, then a thin tail to 18. That is a clean, useful distribution — arguably one of the better EDGEX operational metrics we are currently not showing.
The purchase tape also carries PURCHASE_DATE and FUNDING_DATE as distinct columns, so BOTH panels are satisfiable: offer->tape uses tape AS_OF_DATE, offer->funding uses FUNDING_DATE.

SEMANTIC POINT worth carrying into the Sean conversation: for v2 the 'offer date' is really the date we SCORED the application, so the panel would honestly read 'days from scoring to purchase'. That is still meaningful — it measures how long Oliv takes to buy after we grade — it just wants renaming, unlike Applications Bid / Approval Rate / Own Rate which want retiring.

So the three-way split for Sean is now: (1) RETIRE or REDEFINE — Applications Bid, Approval Rate, Own Rate (we grade, we do not bid). (2) BUILD — Days from Offer to Purchase-Tape / to Funding, needs a NorthpondFundingLag transform, data is all there. (3) DONE — Applications Owned and Look to Book, both live since the 2026-09-01 backfill.
- 2026-09-09T19:01Z [claude-code] 2026-09-10 DEFINITIVE INVENTORY of what PR #6491 + the 2026-09-01 backfill actually fixed on API Gateway Monitoring. Measured every owned-touching panel through /api/ds/query, then re-ran the identical set against channel=northpond_loan_fl_dark_mode, which still has owned=0 and therefore reproduces the PRE-FIX state exactly. That control is what makes this an inventory rather than an inference.

MEASUREMENT BUG I CAUGHT MID-CHECK: my first pass reported panels 31/32/35/44 as RENDERS because I counted non-nulls in column index 1, which on the breakdown panels is the bucket LABEL (a string, never null), not the value. Corrected to count only fields with schema type 'number'. Panel 32 flipped from 'RENDERS' to 'BLANK' once fixed. Anyone re-running this must inspect numeric fields only.

FIXED — 9 panels (owned=0 control -> BLANK, live loan_fl -> RENDERS):
   8  Look to Book                         30 rows, 60/60 numeric non-null
  15  Applications Owned (timeseries)      30 rows, 60/60
  20  Applications Owned by State (geomap) 15 rows, 15/15
  26  Applications Owned :: Avg. (Averages row)          30 rows, 60/60
  31  Look to Book by breakdown            209 rows, 209/209
  35  % of Applications Owned :: breakdown 209 rows, 209/209
  38  Applications Owned :: breakdown (barchart)  15 rows, 15/15
  44  Applications Owned :: Avg. by breakdown     209 rows, 209/209
  12  stat Applications Owned — DIFFERENT CASE: it never went blank, it rendered a WRONG 0. Now 451.
So 8 panels went blank->rendering and 1 went wrong-value->right-value.
Mechanism for the 8: they all carry HAVING SUM(owned_apps_...) > 0, so with owned=0 every row was eliminated and Grafana got zero rows. Panel 26 additionally needed AVERAGES:<metric>:owned, which was literal NULL before because owned_join_table='' forced NULL as avg_*_owned.
Note 4 of the 9 (26, 31, 35, 38, 44) live inside the COLLAPSED Averages / Breakdown rows — easy to miss when eyeballing the dashboard.

STILL BLANK — 4 panels, two distinct causes:
   9  Own Rate            = owned/NULLIF(approved,0)  -> 30 rows, 0/60 numeric non-null
  32  Own Rate by breakdown, same formula             -> 209 rows, 0/209 non-null
      Both blocked on the bid half; blank on v1 too, and no owned backfill can help them.
  53  Days from Offer to Purchase-Tape Date           -> 0 rows
  54  Days from Offer to Funding                      -> 0 rows
      Both read gold.funding_lag, which has zero northpond rows because no NorthpondFundingLag transform exists.

The Bid family (7 Approval Rate, 11 stat Bid, 14 ts Bid, 19 geomap Bid, 25 Avg Bid, 30, 34, 37, 43) was never in scope for this PR and is unchanged.
- 2026-09-09T19:36Z [claude-code] 2026-09-10 REAL DEFECT FOUND — Applications Owned under-reports by 28% and has a permanent dead zone at the leading edge. Abhishek spotted it visually ('no data points in the last ten days, just one on some random day'); he was right.

MEASURED. gold owned total 465 vs live truth 646 = 181 owned applications MISSING (28%). Per offer-date, gold vs truth: 08-28 8 vs 20 | 08-29 0 vs 14 | 08-30 0 vs 12 | 08-31 0 vs 18 | 09-01 0 vs 21 | 09-02 14 vs 32 | 09-03 0 vs 28 | 09-04 0 vs 23 | 09-05 0 vs 14 | 09-06 0 vs 8 | 09-07 0 vs 7. Older dates are slightly short too (08-20 26 vs 27, 08-24 15 vs 16, 08-25 18 vs 20) because purchases keep landing against old offer dates. The lone 09-02 spike he noticed is a date that happened to get reprocessed later, when late-arriving OFFER rows for 09-02 triggered a rebuild of that key and the tape was by then populated.

MECHANISM. owned is attributed to the application's FIRST OFFER date, but the transform only reprocesses a date when new OFFER rows arrive for that date. A purchase tape landing does not trigger a rebuild of the older offer date it belongs to. Offer->purchase lag is 2-18 days (median 4), so by the time a purchase is known the offer date is long out of the incremental window. Result: the last ~2-3 weeks are always understated and drift down permanently until someone runs as_of_date: all again.

ROOT CAUSE IS A MISSING StreamSource, AND NORTHPOND IS THE ONLY PLATFORM WITHOUT IT:
  upgrade_offers_daily/_bucketed:    silver.upgrade_stmt_purchase_tapes  reload_all_on_change=True (+ allocations)
  sofi_offers_daily/_bucketed:       silver.sofi_stmt_purchase_tapes + initial_purchase_tapes, both reload_all_on_change=True
  prosper_offers_daily:              silver.prosper_stmt_accepted_report reload_all_on_change=True
  happymoney_offers_daily:           silver.happymoney_stmt_originations reload_all_on_change=True
  northpond_tu_offers_daily/_bucketed  and northpond_exp_offers_daily/_bucketed: OFFERS TABLE ONLY. No tape source.
Upgrade's own in-code comment describes this exact failure: 'an allocation AS_OF_DATE is the origination day but it marks owned at the earlier offer date, so an incremental reload keyed off its own dates would rebuild the wrong rows and never fill the leading edge.'

I CALLED THIS WRONG IN PR #6491. I noted the missing source_tables entry and wrote it off as 'pre-existing v1 behaviour, deliberately left alone'. It is not benign — it is a 28% undercount and a visibly broken chart. It should have been in scope.

FIX (follow-up PR, 4 files): add StreamSource(table='silver.northpond_stmt_purchase_tapes', reload_all_on_change=True) to northpond_exp_offers_daily, northpond_exp_offers_bucketed, northpond_tu_offers_daily, northpond_tu_offers_bucketed — mirroring the other five platforms exactly. Then one as_of_date: all backfill of all four assets to fill the current hole. Same no-shared-code, platform-file-only shape as #6491. NOT STARTED — his call whether I open it.
- 2026-09-09T19:45Z [claude-code] 2026-09-10 Run-config conventions checked against the docs he pointed at, for future handovers.

PRIORITY IS A TAG, NOT RUN CONFIG — the gotcha. notes/areas/efp/runbooks/dagster-prod-run-queue.md: set dagster/priority (integer, default 0, higher first) in the Launchpad TAG EDITOR, not the YAML box. Verified empirically 2026-09-04 in that runbook: a pri=10 copy_from_efs run jumped nine runs queued 21 minutes longer. Priority REORDERS, it does not preempt — you still wait for a slot. And it CANNOT be added to an already-queued run; cancel and relaunch. Instance runs QueuedRunCoordinator with max_concurrent_runs: 10; the queue saturates at top-of-hour when six statements_* jobs launch together and run 60-90 min.

WAREHOUSES ACTUALLY AVAILABLE (SHOW WAREHOUSES, 2026-09-10): COMPUTE_WH_L (Large), COMPUTE_WH_M_ETL (Medium), COMPUTE_WH_S (Small), COMPUTE_WH_XS_PROD, COMPUTE_WH_XS_DEV, COMPUTE_WH_XS_GRAFANA, COMPUTE_WH_CI (all X-Small). So the 'large warehouse' is COMPUTE_WH_L — there is NO _PROD-suffixed larger option. Precedent: statements_lc runs as_of_date=all on COMPUTE_WH_L.
Note the [[snowflake-warehouse-naming]] rule (only _DEV/_PROD suffixed, narrow rather than size up) governs AGENT queries, not a prod job Abhishek launches himself — COMPUTE_WH_L is legitimate there.

FOR THIS PARTICULAR JOB IT IS UNNECESSARY: the northpond_exp_offers_daily / _bucketed as_of_date=all runs took 20s and 19s on COMPUTE_WH_XS_PROD (287,043 source rows). A Large warehouse buys nothing on a 20-second job. The priority tag IS worth setting if the queue is saturated. Recommended handover config from here on: as_of_date: all + warehouse COMPUTE_WH_XS_PROD in the config box, dagster/priority: 10 in the tag editor.
- 2026-09-09T19:47Z [claude-code] 2026-09-10 WAREHOUSE ROUTING — master has moved since my earlier handovers and my advice needs updating. Abhishek pasted the Launchpad config showing an event_types field I had not seen.

event_types: [] — new field on TransformConfig (asset_factories.py:29). 'Restrict the run to these bronze event types; empty means all. Honoured only by transformations whose constructor accepts event_types (today, api_field_presence).' The factory passes it as a kwarg only when non-empty, so setting it on a transform that does not accept it raises TypeError. For the northpond offers assets: LEAVE IT EMPTY.

warehouse_tier / resolve_warehouse — edgefocus/transformations/warehouse_routing.py, new since I last read this code. WarehouseTier enum: XS_PROD (default), M_ETL, M_ETL_ON_REBUILD. DEFAULT_WAREHOUSE=COMPUTE_WH_XS_PROD, DEFAULT_ETL_WAREHOUSE=COMPUTE_WH_M_ETL, overridable by the ETL_WAREHOUSE env var (blanking it is the documented rollback). routing_enabled() only when ENVIRONMENT=prod, because COMPUTE_WH_M_ETL grants USAGE to PROD_WRITER only. REBUILD_KEY_THRESHOLD=32 — a date range or comma list of >=32 keys counts as a rebuild for routing.

PRECEDENCE, and this is the counter-intuitive bit: resolve_warehouse overrides the configured warehouse ONLY when it equals the shared default COMPUTE_WH_XS_PROD. Any other explicit value WINS and disables routing. So typing COMPUTE_WH_L in the config box does not 'add' a big warehouse on top of the tier system — it PINS the run and bypasses it. Leaving COMPUTE_WH_XS_PROD is what lets a transform's own tier promote it.

APPLIED TO THESE ASSETS: northpond_exp_offers_daily, _bucketed and northpond_tu_offers_daily declare NO warehouse_tier, so they default to XS_PROD and stay on COMPUTE_WH_XS_PROD whatever routing does. upgrade_offers_daily and upgrade_offers_bucketed declare warehouse_tier = WarehouseTier.M_ETL_ON_REBUILD.

CONSEQUENCE FOR THE PLANNED FIX — the follow-up PR is probably not 12 lines but 12 + 4. Upgrade pairs its reload_all_on_change tape sources WITH M_ETL_ON_REBUILD routing, precisely because reload_all makes every tape landing a full rebuild. If we add reload_all_on_change to the four northpond transforms without the tier, every daily tape landing triggers a full-range rebuild on XS. Today that is ~20s so it is genuinely fine, but the upgrade precedent is to tag the tier at the same time. Decide deliberately rather than by omission.
- 2026-09-09T19:54Z [claude-code] 2026-09-10 Leading-edge hole filled by a manual re-run. Run 94f651d4-6854-4b8c-a582-5be24b1c73dd, northpond_exp_offers_daily alone, as_of_date: all on COMPUTE_WH_M_ETL, SUCCESS in 0.42 min.
PROD gold now: v2 owned 465 -> 646, exactly matching the live truth computed from silver. v1 unchanged at 372.
Dead zone gone: 08-28 8->20, 08-29 0->14, 08-30 0->12, 08-31 0->18, 09-01 0->21, 09-02 14->32, 09-03 0->28, 09-04 0->23, 09-05 0->14, 09-06 0->8, 09-07 0->7. 09-08 and 09-09 read 0, which is CORRECT not stale — minimum offer->purchase lag is 2 days, so those offer dates have no purchases yet.
Note M_ETL took 25s vs XS's 20s on the same work, i.e. the warehouse size made no difference here as expected.
STILL TO RUN: northpond_exp_offers_bucketed, same config — it feeds Owned by State plus the four Breakdown-row panels (31, 35, 38, 44), which remain stale until it runs.
AND THIS WILL DECAY AGAIN within days. The manual re-run is a snapshot; the durable fix is still the reload_all_on_change tape source (+ M_ETL_ON_REBUILD tier, mirroring upgrade) on the four northpond transforms. Not started.
- 2026-09-09T19:59Z [claude-code] 2026-09-10 BOTH ASSETS RE-RUN, dashboard fully current. Run b634b7e2-6e2d-4dc7-81ca-9627a4acae29 (northpond_exp_offers_bucketed, as_of_date: all, COMPUTE_WH_M_ETL, dagster/priority 10) SUCCESS in 0.63 min.
Daily and bucketed now AGREE on both versions: v1 372/372, v2 646/646. That is the cross-table check that matters since the geomap and the stat row are computed independently.
Panel sweep re-run: the 9 fixed panels all render with more data than before (timeseries 30 -> 39 day-points, breakdown panels 209 -> 293 rows). The 4 known-blank remain blank for their own documented reasons: 9 and 32 Own Rate (owned/approved, approved=0), 53 and 54 Days-from-Offer (gold.funding_lag has no northpond rows).

DEV-1510 IS NOW OPERATIONALLY COMPLETE for the owned half. Remaining open threads, none of them started:
1. DURABLE FIX for the decay — reload_all_on_change tape source + M_ETL_ON_REBUILD tier on the four northpond offers transforms. Without it this whole exercise repeats in ~2 weeks.
2. TEARDOWN — dashboard /d/dev1510-npv2-owned, DROP DEV_ABHISHEK.GOLD.OFFERS_DAILY_DEV1510 and OFFERS_BUCKETED_DEV1510, REVOKE SELECT FROM ROLE GRAFANA_READER. Prod is verified so the before/after comparison has served its purpose.
3. NOTE TO SEAN — retire or redefine Applications Bid / Approval Rate / Own Rate (we grade, we do not bid on v2); build NorthpondFundingLag for the two Days-from-Offer panels (data all present, median lag 4 days).
4. Confirm with Nate that Oliv prices off our grade, closing the one caveat on the we-do-not-bid finding.
- 2026-09-09T20:43Z [claude-code] 2026-09-10 DURABLE FIX RAISED — PR #6755 (DRAFT) https://github.com/edgefocus/efp/pull/6755, branch abhishek/dev-1510-northpond-offers-tape-reload off current master (d47cbc31b).
Adds StreamSource(silver.northpond_stmt_purchase_tapes, reload_all_on_change=True) to all FOUR northpond offers transforms (exp+tu, daily+bucketed), with a comment explaining why reload_all rather than incremental. 4 files, +24 lines, platform-specific only, no shared code.
Local checks before pushing: ruff clean, ruff format clean, mypy clean, 76 tests pass (offers_bucketed_utils_test + asset_factories_test).
PR body carries the before-numbers in a collapsible (query + result), the 465 vs 646 gap, and a precedent table showing upgrade/sofi/prosper/happymoney all already do this and northpond was the only holdout.
DELIBERATE OMISSION, stated in the PR: did NOT add warehouse_tier = M_ETL_ON_REBUILD even though upgrade pairs it with this flag. Measured justification — a full northpond rebuild is 20s on XS_PROD and 25s on M_ETL, so the tier (which exists to keep heavy rebuilds off XS) buys nothing here. Flagged as worth revisiting if volume grows.
AFTER MERGE: deploy-dagster-prod is workflow_dispatch only, then one as_of_date: all run of the four assets to clear the current backlog; self-healing from then on.
- 2026-09-10T13:03Z [claude-code] 2026-09-10 REVIEW FINDING ON PR #6755 WAS REAL — a reviewing agent flagged watermark starvation on the new tape source. Verified and fixed in commit 5af01c518.

THE BUG. The watermark key is SOURCE -> TARGET (StreamPipeline._get_composite_pipeline_name). NorthpondTuOffersDaily and NorthpondExpOffersDaily both write gold.offers_daily; the two bucketed ones both write gold.offers_bucketed. My first commit gave all four the SAME new source, silver.northpond_stmt_purchase_tapes. So each pair resolved to ONE cursor — whichever transform ran first would advance it, the other would find no changed keys and skip the very rebuild the PR exists to trigger. The reviewer described the mechanism correctly.

The codebase already names this hazard verbatim. StreamSource.scoped_watermark docstring: 'Set it only when multiple transforms write the same target and would otherwise share (and starve on) one cursor for this source.' And _get_composite_pipeline_name: 'without it they resolve to one name, share one cursor, and the first to run advances it past the others rows so they starve.' Existing users: the tu standardized_loans strict/loose siblings.

WHY NO OTHER PLATFORM HITS IT: upgrade/sofi/prosper/happymoney each own a platform-specific tape table, so even though they share gold.offers_daily, only one transform consumes each tape. NorthPond is the only platform where TWO transforms (TU and EXP) read ONE tape into ONE target. My precedent table was right about the pattern and blind to this difference.

FIX: scoped_watermark=True on the tape source in all four files. PROVED it works by instantiating all four transforms and comparing _get_composite_pipeline_name — 4 transforms, 4 distinct cursors:
  ... -> GOLD.OFFERS_DAILY[PLATFORM=NORTHPONDANDAPI_VERSION=2] / [=1]
  ... -> GOLD.OFFERS_BUCKETED[PLATFORM=NORTHPONDANDAPI_VERSION=2] / [=1]

PRECONDITION CHECKED, not assumed. scoped_watermark must only go on a NEW source edge or it replays the whole backlog. Queried PROD.OPS.PIPELINE_WATERMARKS (columns are PIPELINE, LAST_PROCESSED, UPDATED_TS): there is NO SILVER.NORTHPOND_STMT_PURCHASE_TAPES -> GOLD.OFFERS_* row, so the edge is new and the default epoch start is correct. Other platforms tape edges DO exist there unscoped, e.g. SILVER.ANCHORED_STMT_PURCHASE_TAPES -> GOLD.OFFERS_DAILY.

Checks after the fix: ruff, ruff format, mypy clean; 176 tests pass (offers_bucketed_utils, asset_factories, and the whole edgefocus/data_warehouse suite which covers stream_pipeline).
PR body updated with a 'Why scoped_watermark=True' section. NOTE the PR is no longer draft — Abhishek marked it ready while I was working; commit 5af01c518 landed on the ready PR.
