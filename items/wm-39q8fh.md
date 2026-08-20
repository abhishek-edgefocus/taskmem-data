---
id: wm-39q8fh
type: task
title: NorthPond FUND attribution races Oliv's issuance_v2 arrival — newest as_of_date is always stale
status: next
priority: high
tags: [northpond, edgex, dashboards, data-quality]
links: [relates:wm-cqgb5n, relates:wm-d7m3xz]
created: 2026-08-19T20:04:30Z
updated: 2026-08-20T19:27:52Z
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

## Log
- 2026-08-19T20:54Z [claude-code] Refined the characterisation 2026-08-20: the 46 orphaned loans are NOT newly-seen loans. All 46 were already in silver.positions from 2026-08-15..08-18 under fund=to_be_purchased_edgex20261NN, and issuance_v2 called them CURRENT_INVESTOR='oliv' on 08-17/08-18 before flipping all 46 to 'edgex20261NN' on 08-19 (that flip IS the sale event). So the loan and its EDGEX destination were both already known; only the sale-happened-today signal is applied late. Feed arrival medians (IST): positions ~18:08, issuance v1 and v2 both ~22:07 (measured over 20-30 days of S3 LastModified; dpx is UTC). FUND is stamped on the nelnet stmt tape at ~18:18 IST off the previous day's issuance; to_be_purchased rebuilds ~00:40 IST off the fresh one. Net: the sale is applied same-day on the to_be_purchased side and one day late on the purchased side, so the day's purchases are removed from one bucket without being added to the other.
- 2026-08-19T21:09Z [claude-code] Raised PR #6394 (branch abhishek/northpond-fund-issuance-dep, workspace dp:~/claude-ws/fund-race/efp): declares silver.northpond_stmt_issuance_v2 as a StreamSource with reload_subsequent_on_change=True on NorthpondStmtNelnetPositions. +14 lines, one platform-specific file, no shared code. ruff/mypy clean, 207 northpond tests pass. Proof in the PR: rebuilding FUND for 2026-08-19 with the production _FUND_EXPR yields edgex20261NN=200 vs the stored 154. Chose reload_subsequent_on_change over required=True so a late/absent Oliv issuance file cannot stall balances for the day. Deploy note: new source edge, so first run reprocesses the whole Nelnet history (Aug 2026 onward) and self-repairs 08-19. FCC leg (stmt_positions/stmt_transactions) has the same undeclared dependency, left as a follow-up.
- 2026-08-19T21:48Z [claude-code] Added the strategic fix to the same PR #6394 (now +198/-20 across 3 files, 2 commits). Part 2 rewrites the to_be_purchased termination predicate: new owned_state CTE unions silver.northpond_stmt_positions (LOANNUMBER) and northpond_stmt_nelnet_positions (LOAN_EXTERNAL_REFERENCE_ID), and membership now ends on 'an owned row for this date carries a real fund' instead of 'CURRENT_INVESTOR still maps to balance sheet'. Both buckets therefore read the same stamped FUND and partition the intended population regardless of feed timing. A row under ANY real fund terminates, preserving the resale exclusion. Also added the mirror gap ValidationRule (overlap was already guarded; the gap was not, which is why this ran silently). Key insight came from Abhishek: INTENDED_INVESTOR named these loans for EDGEX from day one (verified: all 46 had INTENDED=edgex20261NN from 08-15 while CURRENT stayed 'oliv' until the 08-19 flip), so the dashboard total was always meant to be invariant to the flip timing. Prod verification on 08-19 using the transform's own generated SQL: Oliv intends 354 loans; prod shows 154 owned + 154 pending = 308; new membership yields 200 pending -> 354 whole. Gap rule replayed against prod returns exactly 46. ruff+mypy clean (1059 files), 212 tests pass.
- 2026-08-20T18:52Z [claude-code] 2026-08-21 00:22 IST: PR #6394 deliberately HELD BACK from the review post — Abhishek is not satisfied with it yet. #6390/#6393/#6401 went out; #6394 did not. Known open gaps on it: 4 substring-in-SQL test assertions (against the new draft-until-ready rule), first run reprocesses every Nelnet date (watermark from epoch), and it was validated on 2026-08-19 only.
- 2026-08-20T19:02Z [claude-code] Recurrence confirmed 2026-08-20 (PR #6394 still OPEN/unmerged, so prod unchanged). The bug fired again: 31 loans / $79,304 stranded on as_of 2026-08-20 (staleness-bounded rule). Same timing pattern - nelnet tape stamped 05:52:54 PT, issuance_v2 landed 10:22:08 PT. 2026-08-19 has NOT self-healed after 33h: still 46 loans / $102,831.98 stranded, value frozen as stamped. Confirms past dates stay wrong permanently until reprocessed. Now 2-for-2 on days the normal daily schedule ran unassisted (08-19, 08-20); 08-14..08-18 are clean only because of the 08-18 15:30 bulk backfill that ran after issuance landed at 15:10. IMPORTANT for detection: the bug is silent by construction. Plotted value = true population minus that day's stranding, so the day-over-day change is (genuine growth - change in stranding). On 08-19 stranding jumped 0->46 and outweighed growth, so the line FELL (visible, which is how Abhishek spotted it). On 08-20 a lot settled (intended 354->390) and stranding shrank 46->31, so the line ROSE and looked healthy while still $79K short. Do not treat 'the chart looks fine' as evidence the bug is gone - only the intended-vs-shown gap query is evidence. Plotted: 08-17 $721,191 / 08-18 $802,948 / 08-19 $790,545 / 08-20 $897,142 (should be $976,446).
- 2026-08-20T19:27Z [claude-code] Split PR #6394 back to commit 1 only (+14/-1, one file) on 2026-08-20 after review. Could not produce a date/asset that stays wrong with only the stream fix: zero loans across 08-14..08-20 have CURRENT_INVESTOR=edgex without a servicing-tape row, all 31 stranded on 08-20 sit on a tape as northpond_balancesheet, and northpond_positions already sources both tapes so the re-stamp propagates. Convergence-lag defect, not membership semantics. Partition rewrite + gap rule preserved on branch abhishek/northpond-partition-intent (8174e2638), no PR, tracked in wm-c4w87n with the two review issues that must be fixed first.
