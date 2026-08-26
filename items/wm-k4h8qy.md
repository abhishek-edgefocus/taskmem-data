---
id: wm-k4h8qy
type: task
title: DEV-1510: NorthPond approved/originated tracking blank on API Gateway Monitoring
status: next
priority: p2
links: [relates:wm-unb6pr]
created: 2026-08-22T08:15:32Z
updated: 2026-08-26T20:11:03Z
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
