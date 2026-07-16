---
id: wm-u7d75w
type: task
title: Deprecate northpond datastores: 2 registry entries + HISTORY_DERIVED / renames calls
status: active
priority: p1
size: s
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-16T12:53:08Z
updated: 2026-07-16T12:53:24Z
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
