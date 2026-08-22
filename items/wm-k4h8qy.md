---
id: wm-k4h8qy
type: task
title: DEV-1510: NorthPond approved/originated tracking blank on API Gateway Monitoring
status: next
priority: p2
created: 2026-08-22T08:15:32Z
updated: 2026-08-22T08:15:38Z
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
