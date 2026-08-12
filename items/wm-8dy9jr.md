---
id: wm-8dy9jr
type: task
title: Nelnet loan file is landing raw SSN/DOB/bank details into efp-raw (the NON-PII bucket)
status: next
priority: p1
size: s
people: [Nate, Trishit]
tags: [northpond, edgex, compliance]
links: [relates:wm-gj5tkx, relates:wm-nwvcg9]
created: 2026-08-12T15:29:33Z
updated: 2026-08-12T16:36:50Z
source: claude-code
---

Found 2026-08-12 while assessing Nelnet ingestion ([[wm-gj5tkx]]). This is a live exposure, not a hypothetical, and it is independent of whether we ever parse the file.

WHAT IS EXPOSED
s3://efp-raw/statements/northpond/nelnet/daily_loan/YYYY/MM/VELOCITY_SERVICING_DF2_* — 13 daily files so far (2026-07-31 through 2026-08-12), 353 borrowers in the latest. Every row carries, in the clear:
  - field 229/230 first + last name
  - field 233 date of birth
  - field 234 AND field 328 full SSN (twice)
  - fields 235-240 street address, city, state, ZIP
  - field 243 phone, field 248 email
  - fields 264-267 bank account nickname, account holder name, account type and ROUTING NUMBER (3 rows in the 08-12 file)

WHY IT IS IN THE WRONG BUCKET
efp-raw is the non-PII bucket; efp-pii is the PII one (edgefocus/transformations/bronze/strip_statement_pii.py, PII_BUCKET = 'efp-pii'). Routing is driven by StatementPlatformConfig.is_pii, and NORTHPOND_CONFIG in bronze/platform_configs/northpond.py has pii_columns={} — northpond is declared to have no PII at all, so the file routes straight to efp-raw.

TWO REASONS THE EXISTING STRIPPER WOULD NOT SAVE US EVEN IF WE SET pii_columns
1. _strip_pii_from_file dispatches on file extension and only handles .csv and .xlsx; anything else is returned unchanged. The Velocity DF2 S3 key ends in a bare '.' with no extension, so it is a pass-through.
2. _columns_to_drop matches PII by COLUMN NAME. The file is headerless and positional, so there are no names to match. Positional stripping does not exist today.

So closing this needs a code change, not just a config change.

NOTE the transaction file leaks less but is not clean either: V_Transaction_Detail_Export_Daily_OlivFinancial_*.xlsx carries borrower Last Name. That one IS .xlsx with named columns, so the existing stripper would handle it with a pii_columns entry alone.

CONNECTS TO
Nate raised exactly this in the DM on 2026-08-12 03:20 IST ('There's PII in the loan tape', 'We're passing the full/raw file right now via sftp') and offered to send a cleaned CSV instead. Abhishek promised 'I think we can not ingest pii in our system - I will confirm and get back' — that promise is [[wm-nwvcg9]]. Accepting Nate's clean-CSV offer would resolve this at source and is the cheapest fix by a distance.
Same underlying 'what are we allowed to hold' policy question as [[wm-9kvv8c]].

IMMEDIATE ACTIONS TO CONSIDER (needs Abhishek's call, none taken)
- Decide whether the 13 already-landed files should be purged or moved to efp-pii.
- Answer Nate on the PII policy so Oliv can stop sending it.

## Log
- 2026-08-12T16:36Z [claude-code] NARROWED 2026-08-12 after the Nate call transcript. The go-forward half of this is DECIDED: EF will not ingest PII, and Nate has agreed to deliver a truncated PII-free file (he already produces that shape for other loan buyers). So the code changes I scoped this morning — positional PII stripping and extension dispatch in strip_statement_pii.py — are NOT needed, provided the replacement file arrives as a named-column CSV. If it does, the existing pii_columns mechanism plus S3CsvFile covers everything.
WHAT REMAINS IS PURELY CLEANUP, and it is still real: the 13 daily VELOCITY_SERVICING_DF2_* files already sitting in s3://efp-raw/statements/northpond/nelnet/daily_loan/ (2026-07-31 through 2026-08-12) still contain plaintext SSN, DOB, address, phone, email and bank routing numbers for up to 353 borrowers, in the NON-PII bucket. Deciding whether those are purged or moved to efp-pii is Abhishek's call and is unaffected by the source-side fix.
Also note the raw feed will keep landing until Oliv actually cuts over to the truncated file, so the exposure grows by one file a day until then. Worth confirming the cutover date with Nate.
