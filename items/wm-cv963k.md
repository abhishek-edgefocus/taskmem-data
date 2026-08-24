---
id: wm-cv963k
type: task
title: Carry IS_JOINT for OpenRoad - the secondaryBorrower IS in bronze, silver just never extracts it
status: open
priority: p2
tags: [openroad, data-quality]
created: 2026-08-24T15:00:17Z
updated: 2026-08-24T20:44:45Z
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

## Log
- 2026-08-24T20:44Z [claude-code] BLOCKED ON A RULE, NOT ON DATA — investigated 2026-08-25. My earlier framing ("two edits, the data is in bronze") was half right and I would have shipped a regression on it.

THE DATA IS REACHABLE. Joining the purchase tape's OFFER_UUID to bronze.api_events through the same
LATERAL FLATTEN(payload:response:offers) path openroad_offers.py uses, 34 of 35 loans match an
event (the 35th is openroad_5462736, which has no UNIQUE_OFFER_KEY at all), and the secondary zip
resolves exactly for both loans the datastore calls joint:
  openroad_4944443 -> 30223   datastore is_joint True
  openroad_5129970 -> 76112   datastore is_joint True
Control loans with no co-applicant come back NULL, so the path is right.

THE RULE DOES NOT REPRODUCE. Six loans carry a secondaryBorrower zipCode in bronze; the datastore
flags only two. Implementing the documented legacy rule (presence of secondaryBorrower.zipCode)
would take silver from 2 disagreements to 4 - worse, in the opposite direction. Tested three
candidate discriminators against the 2026-08-09 datastore snapshot, all identical:
  any event for the offer   -> flags 6, agree 30/34, 4 false-positive, 0 false-negative
  latest event per offer    -> flags 6, agree 30/34, 4 false-positive, 0 false-negative
  APPROVED offers only      -> flags 6, agree 30/34, 4 false-positive, 0 false-negative
The four extra are openroad_4972236, 5186687, 5215393, 5865766. Zero false negatives in every
variant, so the gateway request is a strict superset of what legacy calls joint - the discriminator
is somewhere legacy reads and I have not found it, not in how the offer or event is chosen.

SO THIS IS A QUESTION BEFORE IT IS A TASK: do those four loans actually have co-applicants? If they
do, silver flagging 6 is MORE correct and the datastore is under-reporting - in which case this
should be implemented and registered as a verified difference in silver's favour, not matched to
legacy. If they do not, legacy applies a condition we have not identified and implementing on
presence alone ships a known-wrong mapping. Not implementing until that is settled; shipping the
naive rule to clear the column would be exactly the kind of board-clearing Abhishek ruled out.
