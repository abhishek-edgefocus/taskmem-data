---
id: wm-m2wjsr
type: task
title: Backfill the null status_at_purchase rows in silver.positions for northpond (DEV-1522)
status: next
priority: p2
size: s
people: [Abhijeet]
tags: [northpond, data-quality]
links: [parent:wm-3sxcre]
refs: [DEV-1522=https://linear.app/edge-focus/issue/DEV-1522/fix-northpond-status-at-purchase, PR-6207=https://github.com/edgefocus/efp/pull/6207]
created: 2026-08-11T08:49:02Z
updated: 2026-08-19T19:44:35Z
source: claude-code
label: northpond status_at_purchase nulls
---

Filed by **Abhijeet** on 2026-08-10 14:55Z, assigned to Abhishek. Backlog, unstarted.
Branch name already reserved: `abhishek/dev-1522-fix-northpond-status_at_purchase`.

The ticket in full: a few rows in `silver.positions` have a NULL `status_at_purchase`.
PR #6207 adds validations to stop new ones appearing, but **the existing offenders still
need fixing** — that remediation is what this ticket is for, and it is the half a
validation PR does not do.

Not yet established (do this before scoping): how many rows, which loans, which funds, and
whether they cluster around a known event — a purchase-tape gap, the efhyf/experimental
split, or the 2-8 day lag between purchase and the loan appearing on the daily tape
([[wm-k3wt84]], done). A validation that starts failing on legitimately-NULL historical
rows would be a second problem.

Captured here because it was assigned by someone else and had no taskmem item — nothing in
Slack mentions it.

## Log
- 2026-08-19T19:12Z [claude-code] Scoped down: of 773 NULL status_at_purchase rows for northpond, 771 are to_be_purchased_edgex20261NN pending-purchase rows (legitimately NULL, out of scope for PR #6207). Only 2 real offenders: OLV12563044 (as_of 2025-06-18) and OLV12563061 (as_of 2025-06-24) — earliest positions snapshot lands one day before the inferred purchase TRANSFER_DATE, so the ASOF join in generate_purchases_join() can't match. Fixed via corrections/rules/northpond/2025_06_status_at_purchase_asof_gap.py (first correction file for this platform). Tested in DEV_ABHISHEK via isolated apply_corrections_to_temp_table() run (confirmed correct before/after) rather than a full reprocess, since that dev database is separately missing upstream data for old northpond dates. PR open: https://github.com/edgefocus/efp/pull/6390. Still needed after merge: sync corrections to prod + reprocess northpond positions for 2025-06-18 and 2025-06-24.
- 2026-08-19T19:44Z [claude-code] Reviewed PR #6390 (the corrections-file approach) and it does not hold up. Three problems, all verified against PROD.silver.positions: (1) It patches 1 of 7 columns — on northpond_OLV12563044 2025-06-18 the ASOF miss NULLs STATUS_AT_PURCHASE, PRINCIPAL_AT_PURCHASE, PRICE_AT_PURCHASE, INTEREST_AT_PURCHASE, DPD_AT_PURCHASE, POOL_ID and MARKUP; setting only status_at_purchase leaves the row half-populated. (2) Wrong layer — corrections/ is for tape defects (sofi negative principal, HM missing STATE, upgrade NULL DPD); zero corrections across ALL platforms touch any *_at_purchase column (checked silver.corrections). Every platform that hit this fixed it in COLUMN_MAPPING: northpond itself already does PURCHASE_DATE=COALESCE(pur.TRANSFER_DATE, TRY_TO_DATE(p.CONTRACTDATE)) one line above; lc COALESCEs snapshot/tape/pur; innovate and figure derive from first-seen; upstart added an orig_pur join. (3) Recurring, not one-off — the root cause is transfers.py::_inferred_purchases_leg picking the earliest AS_OF_DATE row but stamping PURCHASE_DATE=TRY_TO_DATE(CONTRACTDATE); 26 northpond loans hit first-seen-before-contract-date in 2026-08-14..17 alone, and 352 loans first-landed in northpond_balancesheet in Aug 2026, so pinning 2 UUIDs will not catch the next one. No validation guards it either (#6207 still open, and it adds no STATUS_AT_PURCHASE IS NULL rule). Recommended instead: PURCHASE_DATE = LEAST(TRY_TO_DATE(p.CONTRACTDATE), p.AS_OF_DATE) in the first-pass leg — fixes all 7 columns for all loans past and future, no per-loan enumeration; needs a northpond transfers rebuild + positions reprocess.
