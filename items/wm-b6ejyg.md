---
id: wm-b6ejyg
type: task
title: LC 'HappenBank' rename broke LC ingestion (7d) and leaked borrower PII into efp-raw (PD #1435)
status: open
created: 2026-09-23T18:54:23Z
updated: 2026-09-23T18:54:23Z
source: pd-1435
---

From PD #1435. LendingClub renamed all delivered files Lending_Club_* -> HappenBank_* on the 2026-09-18 delivery (as_of 2026-09-17). Delivery is healthy; only the name changed.

TWO THINGS TO DO, in this order:

1) PII containment (do first, it is live). 102 plaintext HappenBank_Loan_Static CSVs at s3://efp-raw/statements/lc/ (17 accounts x deliveries 09-18..09-23) carry EmploymentTitle / ZIPCode / AddressCity / AddressState / AnnualIncomeStated. They should have gone to efp-pii with only a _CLEANED copy in efp-raw. Needs Abhishek's decision on who is told and how the objects are moved/purged — not an agent action.

2) Code fix (two platform-specific files, no shared code):
   - edgefocus/transformations/bronze/parsing_rules/lc.py: lc_positions, lc_activity, lc_loan_static, lc_positions_fixed, lc_loan_static_fixed, and the raw-twin ignore rule at :183 — accept (?:Lending_Club|HappenBank) instead of the literal.
   - edgefocus/transformations/bronze/platform_configs/lc.py:67-68: _LOAN_STATIC_CSV / _LOAN_STATIC_XLSX globs likewise.
   Then re-run strip/copy for 09-17 onwards so the CLEANED files exist and bronze backfills. Validate in DEV_ABHISHEK first.

Open question for the vendor / Trishit: is HappenBank permanent, and should the old prefix be retired or kept for history?

Evidence: PROD bronze.STATEMENT_FILES MAX(AS_OF_DATE)=2026-09-16 for all three LC rules; efp-pii has 0 HappenBank files; 0 _CLEANED HappenBank files exist.
