---
id: wm-2awd5c
type: followup
title: Relay review comments to Kabeer on PR #6402 (DEV-1642) and #6403 (ERROR-1692)
status: next
priority: p2
size: xs
people: [Kabeer]
tags: [marlette, review]
created: 2026-08-20T13:14:00Z
updated: 2026-08-20T13:14:04Z
source: claude-code
---

Both PRs verified against the branches; already approved + green CI. Asks to relay:

**#6403 (marlette partial-charge-off threshold 20->50)**
- Take the warning-level log Kabeer offered but did not include. 50 is silent until ~2028 on the current trend (19-22/day, +1.2/month); without a warn the next trip is another hard nightly failure with no lead time.
- Stale comment directly above the changed line still explains the guard as a single-loan workaround for loan id 2088011; the population is now ~20/day from settlement-book growth.
- Note: upgrade (datastore_standardized_positions_upgrade.py:368) and silver (statement_rows/marlette/positions.py:539) both run the identical clamp with no tripwire. marlette is the only site that raises.

**#6402 (marlette recovery into IRR + transaction gate)**
- Add the in-file comment: prosper and innovate already carry the byte-identical override and both explain it; marlette's is bare. It is also the only place a reader learns marlette's TOTAL_NET_CASH_FLOW no longer means what the other 8 platforms' does.
- Add the one-line SQL assertion for the marlette COALESCE gate in silver/cashflows/utils_test.py (the file already pins the default with "t.as_of_date >= la.purchase_date" in sql_sofi at :167 and :216).
- State the post-fix calendar-month NCF figure explicitly. Arithmetic implies 985.577MM vs from-origination 985.578MM, which is the actual proof the tightened gate did not drop payments — but the PR only quantifies the $330,875 recovered, never what the stricter direction removes.
- Invariant worth naming: the add-back adds TOTAL_RECOVERY (SUM of recovery_amount_expr, default principal_amount) into an NCF from which recovery rows' transaction_amount was removed. The MOB path in the same module treats those as different quantities on purpose (utils.py:1900-1904: recovery is a "memo breakout, NOT an additive component"). They coincide for marlette today; nothing enforces it.
- Third copy of the override is the moment to consider a class attribute rather than a fourth. Tracked on DEV-1642.
