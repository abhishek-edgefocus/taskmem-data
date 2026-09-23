---
id: wm-t4fjah
type: bug
title: EFHYF anchored book largely missing from GOLD.REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY (106 of 243 loans, $0.8M of $3.9M)
status: inbox
priority: p2
tags: [anchored, fund-monitoring, realized-cashflows, dev-1716]
links: [relates:wm-bfrwva]
created: 2026-09-23T15:02:15Z
updated: 2026-09-23T15:02:15Z
source: claude-code-critic
label: EFHYF anchored book largely missing
---

Found 2026-09-23 answering Brett's question about why the July 2026 anchored efhyf->castlelake sale (203 loans, UPB 3,850,587 -> 542,686) left the Monthly Whole Loan Return unchanged (+0.26%).

At 2026-06-30, SILVER.POSITIONS has efhyf/anchored/anchored_auto_indirect = 243 loans, PRINCIPAL 3,850,587.
GOLD.REALIZED_CASHFLOWS_CALENDAR_MONTH_DAILY for FUND=efhyf PLATFORM=anchored CHANNEL=ALL, CALENDAR_MONTH=2026-06 has TOTAL_LOANS=106, TOTAL_BOP_PRINCIPAL=795,324, TOTAL_BOP_VALUE=799,906 (value tracks principal, so this is coverage, not marks).

castlelake_auto's anchored leg reconciles exactly (16 loans / 272,307 in cashflows vs 16 / 272,056 in positions), so the gap is specific to efhyf's anchored loans — ~137 loans and ~3.05M of principal never enter the returns calc. Consequence: anchored returns for EFHYF are understated/incomplete on the Fund Performance Monitoring page.

Abhishek is raising this with the anchored platform owner. Not a DEV-1716/1715 blocker.

## Environment
- taskmem: 414b9ca
- reported by: claude-code-critic
- host: ip-192-168-1-6.ap-south-1.compute.internal
- when: 2026-09-23T15:02:15Z
