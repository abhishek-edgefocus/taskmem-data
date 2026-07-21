---
id: wm-u7d75w
type: task
title: Deprecate northpond datastores: 2 registry entries + HISTORY_DERIVED / renames calls
status: review
priority: p1
size: s
due: 2026-07-20
nudge: 2026-07-23
people: [Frank, Eshan]
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-16T12:53:08Z
updated: 2026-07-21T09:05:11Z
source: claude-code
---

Verified 2026-07-16 against code: northpond has ZERO hits in datastore_deprecations.py, positions_snowflake_map.py, transactions_snowflake_map.py. All 5 other platforms (sofi, prosper, marlette, happymoney, upgrade) are already registered.

'Deprecate' here is REGISTRY-BASED, not removal. Nothing is deleted: datastore code, the northpond/ dir, lists.py entries, and the 3 dashboards all stay (dashboards use the '[DEPRECATED] <name>' rename convention — already done for qQl7m9cHk, kWBD-xXIk, uW6qoozDz). The registry adds a warning + enables source='snowflake' routing in get_datastore_data().

## Prereq: DONE
Parity-check silver vs datastore completed for northpond (DEV-1275, DEV-1332).

## Scope — one small PR mirroring the upgrade entry
1. Add 2 entries to DEPRECATION_REGISTRY in lib/efp/stats/datastores/datastore_deprecations.py:
   ('DatastorePositions','northpond') -> silver.positions
   ('DatastoreTransactions','northpond') -> silver.transactions
   each with message/deprecate_after/snowflake_routable=True.
2. JUDGEMENT CALL — PLATFORM_RENAMES (positions_snowflake_map.py:37): only needed if legacy
   cols don't uppercase-map. Decide account_name->ACCOUNT_ID: sofi/prosper/marlette do it,
   upgrade deliberately does NOT (its account_name is a human label). Which is northpond?
3. JUDGEMENT CALL — HISTORY_DERIVED_PLATFORMS (positions_snowflake_map.py:82), currently
   {prosper, marlette, happymoney, upgrade}; sofi is the only exclusion, because it has no
   transfers. NORTHPOND HAS FUND TRANSFERS (Experimental->EFHYF) => likely history-derived,
   NOT sofi-style. Confirm before shipping.

## Blockers: NONE (double-checked 2026-07-16)
Abhishek's belief confirmed. An earlier audit flagged the DEV-1024 v2-filter dashboard and
~30 cross-platform dashboards reading datastore positions_ via mysql as blockers — that was
based on a 'deprecate == delete' misreading and is RETRACTED. Registry entries are additive:
those dashboards query MySQL directly, never touch get_datastore_data(), so they are
unaffected by the registry.

## Loose thread (not a blocker)
Chandra dependency audit — Abhijeet's ask from 2026-06-25, never confirmed, no Linear issue.

## Links
- Registry: lib/efp/stats/datastores/datastore_deprecations.py
- Maps: lib/efp/stats/datastores/positions_snowflake_map.py (PLATFORM_RENAMES:37, HISTORY_DERIVED_PLATFORMS:82)

## Log
- 2026-07-16T12:53Z [claude-code] Split out of wm-j523sq log entries into its own item — Abhishek is working it now, high priority. Blocker double-check done: none.
- 2026-07-17T13:27Z [claude-code] 2026-07-17: DEV-1450 created; branch abhishek/dev-1450-deprecate-northpond-datastores off master in ~/repos-2/efp (clean copy). Both judgement calls RESOLVED against code+data, one OVERTURNS the earlier hypothesis:

(1) PLATFORM_RENAMES account_name->ACCOUNT_ID: YES (like sofi/prosper/marlette, NOT upgrade). Legacy northpond literally sets account_id=account_name in 3 places, and the values ARE account identifiers ('ef_northpond'/'northpond_efhyf') = exactly silver ACCOUNT_ID's domain.

(2) HISTORY_DERIVED_PLATFORMS: NO — hypothesis was WRONG. Northpond does have fund transfers (372/715 loans move Experimental->EFHYF, confirmed via multiple PURCHASE_DATEs + multiple ACCOUNT_IDs), but that does NOT imply history-derived. Legacy northpond defines first purchase AS ORIGINATION by construction: datastore_stand_pos_first_pass_northpond sets first_purchase_date=ContractDate, principal/price_at_first_purchase=OriginalLoanAmount on EVERY row ('the first purchase for this datastore is happening at origination into experimental fund'). Silver carries those same source fields directly as ORIGINATION_DATE=TRY_TO_DATE(p.CONTRACTDATE) and PRINCIPAL_AT_ORIGINATION=p.ORIGINALLOANAMOUNT. So northpond is a THIRD pattern: origination-anchored renames. History-deriving would have returned the EFHYF transfer event instead of origination for those 372 loans — silently wrong.

(3) NEW, not in prior scope — transactions.account_id must be NULLed (added northpond to PLATFORM_NULL_COLUMNS, like marlette). silver.transactions maps ACCOUNT_ID straight from raw tape ACCOUNT_NAME and the daily tape ALWAYS arrives as ef_northpond, so silver says ef_northpond for 100% of rows while 79.4% belong to efhyf loans. Legacy applies purchase-tape fund adjustment (adjust_fund_information) so legacy says northpond_efhyf. Returning silver's value would be silently wrong for ~79% of rows. Follow-up worth filing: fix silver.transactions to derive ACCOUNT_ID from fund via account_id_from_fund_expr like positions does.

Also checked: service-fee rows DO exist in silver for northpond (8688 'fee' desc rows) so there is NO upgrade-style fee gap. Diff = 3 files/52 insertions, mirrors upgrade precedent ac6bc26ca. ruff+format clean. Note: no dedicated tests exist for these maps (precedent PRs added none). deprecate_after set to 2026-07-31 — CONFIRM date with Abhishek.
- 2026-07-17T15:01Z [claude-code] 2026-07-17: Shipped as PR #5936 (https://github.com/edgefocus/efp/pull/5936), commit 8a857a40e on abhishek/dev-1450-deprecate-northpond-datastores. 3 files/53 insertions. ruff+format+mypy clean, 120/120 datastore tests pass. deprecate_after=2026-07-31 (flagged for reviewer to adjust). Full-history parity NOT run (killed a runaway ~350GB legacy-load parity job on dpx mid-work; mappings are pinned to identical source exprs so it was redundant). Follow-up [[wm-7mtzka]] filed for the silver.transactions ACCOUNT_ID fix. Awaiting review.
- 2026-07-17T17:53Z [claude-code] 2026-07-17: Set deprecate_after=2026-07-20 (coming Monday) per Abhishek, both registry entries + warning messages. Amended commit -> 1d868711f, force-pushed PR #5936. Also fixed PR body (Testing section + reviewer note had been truncated on original create); full body now posted.
- 2026-07-20T13:55Z [claude-code] Told Abhijeet on 2026-07-17 the deprecation PR (efp#5936) gets merged Monday 2026-07-20; deprecation date set to Monday. Abhijeet approved, asked for a description cleanup.
- 2026-07-20T19:45Z [claude-code] REVIEWED PR #5936 'DEV-1450: Deprecate northpond datastore positions/transactions with Snowflake routing' at Abhishek's request, 2026-07-21. VERDICT: technically sound, safe to merge — only blocker is process (mergeStateStatus=BLOCKED, reviewDecision=REVIEW_REQUIRED, i.e. it needs an approving review; mergeable=MERGEABLE, no conflicts). ALL 4 CI CHECKS PASS: Run Tests 8m56s, Run integration tests 33m47s, Seer Code Review, Select tests. Diff is small and purely additive: +53/-1 across 3 files — datastore_deprecations.py (2 registry entries, deprecate_after 2026-07-20, snowflake_routable=True), positions_snowflake_map.py (northpond column map), transactions_snowflake_map.py (northpond in PLATFORM_NULL_COLUMNS). Nothing deleted. I INDEPENDENTLY VERIFIED THE TWO LOAD-BEARING DATA CLAIMS against PROD rather than trusting the comments: (1) account_id NULLing — PR says silver.transactions reports ef_northpond for 100%% of rows while 79.4%% (69,303/87,251) belong to loans that are efhyf in positions. Measured today: 87,647 tx rows, 69,534 on efhyf loans = 79.3%%, silver.transactions.ACCOUNT_ID has exactly ONE distinct value 'ef_northpond', while positions.ACCOUNT_ID carries both 'northpond_efhyf' and 'ef_northpond'. Claim confirmed (small drift from 07-17 is just new data). NULLing is the right call — returning silver's value would be silently wrong for ~79%% of rows. (2) first_purchase=origination mapping — the map points first_purchase_date -> ORIGINATION_DATE and principal/price_at_first_purchase -> PRINCIPAL_AT_ORIGINATION. Verified both are 715/715 POPULATED on the latest snapshot (no NULL leakage into consumers), ORIGINATION_DATE spans 2024-07-02..2026-04-16, SUM(PRINCIPAL_AT_ORIGINATION) 2,525,495. Also consistent with my own earlier finding that 372 of 715 loans migrated experimental->efhyf, which is exactly why northpond must NOT be history-derived — deriving first-purchase from the earliest as-of row would return the EFHYF transfer event rather than origination for those 372. RECOMMENDED: approve and merge. Note it is INDEPENDENT of my PR #5965 (different files entirely — lib/efp/stats/datastores/* vs orchestration/jobs/*), so merge order does not matter.
- 2026-07-20T20:11Z [claude-code] Abhishek asked 2026-07-21 'we had to deprecate everything for northpond datastores but I see only positions and transactions — what else is pending?'. ANSWER: NOTHING. PR #5936 completes the scope; northpond is now at full parity with every other platform. Verified on origin/master: DEPRECATION_REGISTRY contains exactly TWO distinct classes across ALL platforms — DatastorePositions and DatastoreTransactions — registered for happymoney, marlette, prosper, sofi, upgrade (10 entries). #5936 adds the northpond pair, making 12. There is no third class deprecated for anyone, so there is no northpond-specific gap. This also matches this item's own original scope as written 2026-07-16 ('one small PR mirroring the upgrade entry': 2 registry entries + 2 judgement calls). CONTEXT WORTH KEEPING: ~30 other Datastore* classes exist (DatastoreCfframe, DatastorePayments, DatastoreAccounts, DatastoreMobStats, DatastoreFundCashflows, DatastoreOwnership, ...) and NONE are deprecated for ANY platform. That is a programme-wide gap, not a northpond one — they have no Snowflake routing map yet, so they cannot be registered until someone builds the equivalent of positions_snowflake_map / transactions_snowflake_map for each. NOTED REVERSAL, already resolved correctly: this item predicted on 2026-07-16 that 'NORTHPOND HAS FUND TRANSFERS (Experimental->EFHYF) => likely history-derived, NOT sofi-style. Confirm before shipping.' The PR investigated and concluded the OPPOSITE — northpond is deliberately NOT in HISTORY_DERIVED_PLATFORMS — because legacy defines first purchase AS origination by construction (first_purchase_date = ContractDate), so history-deriving would wrongly return the EFHYF transfer event for the 372/715 migrated loans. I verified that independently against prod on 2026-07-21 (ORIGINATION_DATE + PRINCIPAL_AT_ORIGINATION both 715/715 populated) and it is correct. The 'confirm before shipping' instruction was followed and the initial hypothesis was right to be flagged as uncertain. Untouched by design and NOT pending: datastore code, the northpond/ dir, lists.py entries, and the 3 dashboards — deprecation here is registry-based, nothing is deleted.
- 2026-07-20T22:42Z [claude-code] PR approved by Frank; Frank asked Eshan to take a look once before merge (per Abhishek 2026-07-21). Waiting on Eshan's review, then merge — not done yet.
- 2026-07-21T09:05Z [claude-code] ADVANCED to review 2026-07-20/21. Deprecation PRs are up and approved by Abhijeet: github.com/edgefocus/efp/pull/5936 ('good to merge') and pull/5965 (adds assets to the job). Abhijeet approved both (DM ts 1784577318 'approved'). Linear DEV-1450 is In Review. No longer waiting on Eshan — the gate is now merge + deploy, after which the datastores can actually be deprecated (Abhishek: 'he merge and deploy zhalyavar can deprecate datastores', ts 1784574041).
