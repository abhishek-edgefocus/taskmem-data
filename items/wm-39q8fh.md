---
id: wm-39q8fh
type: task
title: NorthPond FUND attribution races Oliv's issuance_v2 arrival — newest as_of_date is always stale
status: next
priority: high
tags: [northpond, edgex, dashboards, data-quality]
links: [relates:wm-cqgb5n, relates:wm-d7m3xz]
created: 2026-08-19T20:04:30Z
updated: 2026-08-19T20:04:36Z
source: claude-code
estimate: <1h
---

Found 2026-08-20 while investigating the EDGEX deployment dashboard
(grafana d/69431967, var-breakdown=platform). NorthPond's outstanding-principal
point for the most recent date is understated; no other platform is affected.

## What is wrong

At as_of_date 2026-08-19, Oliv's own attribution feed
(`silver.northpond_stmt_issuance_v2.CURRENT_INVESTOR`) says **200** loans belong
to `edgex20261NN`. `silver.positions` labels only **154**. The other **46 loans
/ $102,831.98 of principal** sit in `northpond_balancesheet` and are therefore
invisible to the dashboard.

| as_of_date | issuance_v2 says edgex | positions labelled edgex | gap |
|---|---|---|---|
| 2026-08-14 → 08-18 | 113/113/113/129/154 | same | 0 |
| **2026-08-19** | **200** | **154** | **46** |

Dashboard shows $790,544.56 for northpond; correctly attributed it is
$893,376.54. The purchased half alone is understated 21% ($395,839.56 vs
$498,671.54). Visible symptom: the northpond line *falls* 08-18 → 08-19 while
the fund is actively buying.

## Root cause — an asset-ordering race, not a mapping bug

`northpond_fund_expr` (edgefocus/transformations/silver/statement_rows/northpond/constants.py)
resolves FUND from `issuance_v2` via
`MAX_BY(CURRENT_INVESTOR, AS_OF_DATE) WHERE AS_OF_DATE <= <as_of>`.
FUND is stamped when `silver.northpond_stmt_nelnet_positions` materializes, and
is never recomputed afterwards. `silver.positions` inherits it.

Timestamps for 2026-08-19 (all America/Los_Angeles):

| step | time | result |
|---|---|---|
| `northpond_stmt_nelnet_positions` @08-19 computed | **05:48:05** | newest issuance snapshot available was 08-18 → stamps 154 |
| Oliv's issuance_v2 @08-19 lands | **10:18:18** | says 200 |
| `silver.positions` @08-19 built | 11:59:03 | inherits the stale 154 |
| `to_be_purchased_edgex20261NN` built | 12:11:34 | reads issuance_v2 *directly*, so uses the FRESH 08-19 answer |

So the two halves the dashboard adds together are computed against **different
vintages of the same feed**. The 46 loans fall in the crack: excluded from
to_be_purchased (fresh feed says EDGEX owns them) and not labelled edgex
(stale feed says it does not).

08-14 → 08-18 are all correct only because a bulk re-materialization on
2026-08-18 15:30:09 ran *after* issuance_v2 landed at 15:10:20. The daily
schedule on its own leaves the newest date wrong every day.

## Why northpond only

Only NorthPond derives FUND from a separately-landing daily attribution feed
whose arrival is not a dependency of the positions transform. Other platforms
attribute from the purchase tape directly.

## Notes / not-the-cause (ruled out)

- Not double counting: purchased and to_be_purchased are disjoint efp_id sets
  (154 + 154 = 308 distinct).
- Not a stale tape: both FCC and Nelnet tapes are fresh through 08-19.
- Not NULL principal_at_purchase / purchase_date (DEV-1522) — zero nulls in
  this population.
- The 109 `northpond_balancesheet` + `to_be_purchased_edgex20261NN` duplicate
  rows per date are real but do NOT affect this dashboard (balancesheet is
  filtered out). Worth a separate look for platform-level dashboards.
- Separate, also real: panel 379/380 anchor per-fund, so happymoney (latest
  as_of_date 08-17) drops out of the latest-date stat entirely.

## Fix directions (not implemented — investigation only)

1. Make `northpond_stmt_nelnet_positions` depend on that day's issuance_v2
   partition so it cannot run first, or
2. re-materialize the trailing N days of the nelnet stmt tape after issuance_v2
   lands, or
3. resolve FUND at read time in `positions.py` rather than stamping it upstream.

Related: wm-cqgb5n (two fund names at once — same surface, different cause),
wm-uxwcxn (does INV103 mean sold-to vs earmarked-for).
