---
id: wm-cv963k
type: task
title: Carry IS_JOINT for OpenRoad - the secondaryBorrower IS in bronze, silver just never extracts it
status: open
created: 2026-08-24T15:00:17Z
updated: 2026-08-24T15:00:17Z
source: claude-code
---

Found 2026-08-24 answering "is this a fix or an acceptance" for DEV-1638 ([[wm-skvqac]]).
IT IS A FIX. The source data is in Snowflake today and silver simply does not select it.

EVIDENCE. PROD.BRONZE.API_EVENTS, platform openroad:
  endpoint_transactions: 328,406 events, of which 14,385 carry a populated
    payload:request:secondaryBorrower AND a non-null secondaryBorrower:zipCode
  model_requests:        324,462 events, 14,135 with payload:secondaryBorrower at the TOP level
    (note: NOT under :request - the path differs between event types, which is the trap here)
silver.openroad_offers has 50 columns and not one secondary-borrower field, so
openroad/positions.py hardcodes "IS_JOINT": "FALSE" (positions.py:278-280), which the module
docstring records as a known gap deferred under DEV-1154.

WHY IT SURFACED NOW. The two sides agreed on every date up to 2026-05-03 and diverge from
2026-05-04 on the same two loans (openroad_4944443, openroad_5129970). Silver did not regress - it
has always said FALSE. The legacy datastore began reporting True for those two on that date. So
this is legacy gaining information silver cannot represent, and it is the ONLY column where the
datastore is strictly better than Snowflake.

THE FIX, two small edits:
1. openroad_offers.py - select the secondary-borrower presence/zip alongside the other
   primaryBorrower attributes it already reads. Mind the path difference above.
2. openroad/positions.py - map IS_JOINT off that column instead of the hardcoded FALSE, matching
   legacy's rule (presence of secondaryBorrower.zipCode).
Then backfill openroad_offers + positions so history picks it up.

Once this lands, is_joint comes OFF the verified-differences list in [[wm-skvqac]] - it is
registered there today with snowflake_is_correct=False purely as an accepted limitation.

## Provenance
Read-only, 2026-08-24: variant-path counts on PROD.BRONZE.API_EVENTS; column list of
PROD.SILVER.OPENROAD_OFFERS; loan-level DS-vs-SF on 2026-04-20 / 05-03 / 05-04 / 08-09.
