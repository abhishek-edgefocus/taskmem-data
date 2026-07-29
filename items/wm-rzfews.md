---
id: wm-rzfews
type: task
title: NorthPond: trace markup/exposure + model_version, and settle purchase_year semantics
status: open
priority: p3
size: m
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-unb6pr]
created: 2026-07-29T16:38:56Z
updated: 2026-07-29T16:39:30Z
source: claude-code
---

Left open by PR #6058 (merged 2026-07-29). These are the NorthPond positions columns that still differ from the legacy datastore with no traced cause, so they are deliberately NOT in northpond_verified.py — suppressing them under a guess would hide a real divergence.

## 1. markup / markup_band / exposure — untraced (1.82 / 0.98 / 0.98% on 2026-07-19)
MARKUP = NULLIF(PRICE_AT_PURCHASE,0)/NULLIF(PRINCIPAL_AT_PURCHASE,0) (positions_utils.py:937); EXPOSURE = PRINCIPAL*MARKUP + ACCRUED_INTEREST (:953). Both numerator and denominator come from the same purchase-tape leg, so the datastore's one-day at-purchase offset CANCELS in the ratio and interest_at_purchase never enters it. The Grafana board's own annotation ('DS markup calculation uses slightly different interest-at-purchase input for efhyf') is equally untraced. ~13 efhyf loans, deltas <=0.5%. Nobody has ever traced this to code.

## 2. model_version — 100%, brand new
First nonzero 2026-07-19, on the latest date only. Relates to the v1/v2 (TU/Experian) breakdown, DEV-1024. See wm-unb6pr.

## 3. purchase_year / purchase_quarter — a DECISION, not a finding (16.78 / 9.93%)
efhyf loans only. Silver derives them from PURCHASE_DATE = TRANSFER_DATE into efhyf; the datastore derives them from first_purchase_date (original acquisition into experimental). PURCHASE_DATE itself is 0% mismatch — only the derived year/quarter differ. Both readings are defensible. Pick one; if silver's is right, register both columns in northpond_verified.py.

int_rate_at_purchase (98.74%, the largest mismatch on the board) is NOT part of this — tracked separately as wm-gxykru / DEV-503 / PR #5704.

Blocked in practice until the comparison job is running again — see the dead-job item.
