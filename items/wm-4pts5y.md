---
id: wm-4pts5y
type: task
title: Fix stale loan-tape column names: LATEFEERECOVERED / NSFFEERECOVERED / OTHERFEESRECOVERED are 100% NULL
status: open
created: 2026-08-12T13:09:52Z
updated: 2026-08-12T13:09:52Z
source: claude-code
---

## Problem
`edgefocus/transformations/silver/statement_rows/northpond/stmt_positions.py` maps three fee-recovery columns by their pre-2025 header names:

- `ColumnDef("LATEFEERECOVERED", ..., source="LateFeeRecovered")`
- `ColumnDef("NSFFEERECOVERED", ..., source="NsfFeeRecovered")`
- `ColumnDef("OTHERFEESRECOVERED", ..., source="OtherFeesRecovered")`

Northpond renamed all three in the daily loan tape between 2025-04-21 and 2025-05-11 (bisected against S3 headers) to `LateFeeRecoveredAmt`, `NSFFeeRecoveredAmt`, `OtherFeesRecoveredAmt`. `PrincipalRecoveredAmt` / `InterestRecoveredAmt` were already `*Amt` and are unaffected.

## Proof (prod, 2026-08-12)
`SELECT COUNT(*), COUNT(LATEFEERECOVERED), COUNT(NSFFEERECOVERED), COUNT(OTHERFEESRECOVERED), COUNT(PRINCIPALRECOVEREDAMT) FROM silver.northpond_stmt_positions WHERE AS_OF_DATE >= 2026-08-01`
-> `8580 | 0 | 0 | 0 | 1919`

So all three are NULL for every row while the principal-recovery column populates normally.

## Blast radius
Low today. Nothing reads those three columns: `positions.py` does not map them, and no gold/realized-cashflow asset references them. They are silver-staging-only. Fixing it is a 3-line source-name change, but the fix is only correct going forward unless the affected date range is reprocessed.

## Also unmapped from the same tape (13 named columns not landing)
Never mapped: `PaymentRemainingOnNextPaymentDue`, `PerDiem`, `DateOfLastHardship`, `MostRecentDefermentStartDate`, `MostRecentDefermentEndDate`, `FEMAImpacted`, `NextPTPDate`, `NextPTPAmount`, `DMA`, `Autopay`. All still available in bronze `RAW_RECORD`.
