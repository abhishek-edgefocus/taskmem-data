---
id: wm-k4h8qy
type: task
title: DEV-1510: NorthPond approved/originated tracking blank on API Gateway Monitoring
status: next
priority: p2
links: [relates:wm-unb6pr]
created: 2026-08-22T08:15:32Z
updated: 2026-09-01T18:40:11Z
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
