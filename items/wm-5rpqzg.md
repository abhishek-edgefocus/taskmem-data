---
id: wm-5rpqzg
type: task
title: upgrade_verified.py: 6 dead entries keyed by silver names never match
status: open
priority: p3
size: xs
tags: [data-quality]
created: 2026-07-29T16:38:56Z
updated: 2026-07-29T16:38:56Z
source: claude-code
---

Found 2026-07-28 while validating northpond_verified.py in PR #6058.

edgefocus/transformations/silver/comparison/upgrade_verified.py registers 6 entries keyed by SILVER column names:
  itd_payment_principal_received, itd_payment_interest_received, itd_payment_transaction_received (lines ~853-880)
  itd_recovery_principal_received, itd_recovery_interest_received, itd_recovery_transaction_received (lines ~1163-1236)

compare_datastore_positions.py looks up verified differences by the DATASTORE column name (ColumnResult.column_name = old_col, line 578); COLUMN_MAPPING maps cum_payment_* -> ITD_PAYMENT_*. So none of these 6 ever match and those columns keep getting reported as unverified issues.

Upgrade already registers the cum_* forms at lines ~368-391 for the payment legs, so the payment three are harmless duplicates-that-do-nothing; the three cum_recovery_* forms appear to be missing entirely, meaning the recovery legs are genuinely unverified.

Same class of bug the PR bots caught in northpond_verified.py. Confirmed by cross-checking every platform's registered names against COLUMN_MAPPING keys: northpond 21/21 valid, sofi/marlette/upstart/happymoney all clean, upgrade 6 unmatched.

## Next steps
1. Decide with whoever owns Upgrade (Eshan?) whether the 6 should be renamed to cum_* or deleted.
2. Consider a cheap guard so this cannot recur: assert every registered column is a COLUMN_MAPPING key, either as a unit test or a __post_init__ check.

Step 2 is the durable fix and would have caught both this and the NorthPond instance.
