---
id: wm-u7d75w
type: task
title: Deprecate northpond datastores: 2 registry entries + HISTORY_DERIVED / renames calls
status: review
priority: p1
size: s
due: 2026-07-20
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-16T12:53:08Z
updated: 2026-07-20T13:55:37Z
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
