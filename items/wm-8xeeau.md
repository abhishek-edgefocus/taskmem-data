---
id: wm-8xeeau
type: task
title: OpenRoad sent requestUuid as acceptedOfferUuid on loan 5462736 — offer link recoverable by rate
status: open
created: 2026-08-25T14:37:26Z
updated: 2026-08-25T14:37:26Z
source: claude-code
---

Found 2026-08-25 investigating why openroad_5462736 has no prediction. It is NOT a source gap
(that claim is corrected in [[wm-buekcw]]). Every event exists; OpenRoad sent us the wrong
identifier and their booking call failed our validation twice.

THE SEQUENCE, all in PROD.BRONZE.API_EVENTS, platform openroad, channel openroad_auto_refi:
  2024-07-10  model_requests          requestUuid = 2f5a0c60-7eac-48a8-8cb7-4d67fce64564
  2024-07-10  endpoint_transactions   same requestUuid at request.requestUuid and
                                      response.requestUuid; response carries 19 APPROVED offers,
                                      each with its own uuid, all amount 31,451.00 / term 72,
                                      19 distinct interest rates 13.31%..14.89%
  2024-07-12  endpoint_transactions   api_call=post-loan, request.acceptedOfferUuid = 2f5a0c60...
                                      -> CLIENT_ERROR: principalPurchasePrice is "0.0"; must be
                                      positive (i.e. > 0)
  2024-07-15  endpoint_transactions   identical retry, identical rejection
  2024-07-12  FUNDED anyway (purchase tape FUNDED_DATE), 28,218.63 at 14.48%, term 72

So the loan passed decisioning cleanly and was funded, but the acceptance call named the REQUEST
uuid instead of one of the 19 offer uuids, and carried principalPurchasePrice 0.0 (the offers
themselves carry 1.03). The purchase tape then recorded that same wrong value in OFFER_UUID, which
matches nothing in silver.openroad_offers, so UNIQUE_OFFER_KEY is NULL and every offer-sourced
attribute plus the prediction linkage drops for this loan.

THE LINK IS RECOVERABLE, DETERMINISTICALLY. Within that request the 19 offers have 19 DISTINCT
interest rates, so the rate is a unique key. Exactly one matches the funded loan's 14.48%:
  offer 47583904-d4fb-43d5-8f6d-4db64cd638ae -- rate 14.48, term 72 (matches), amount 31,451.00
  (the maximum approved; the borrower drew 28,218.63), maximumLTV 1.25, modelVersion openroad_model
Term matches, rate matches uniquely, amount is a draw-down of the approved maximum. This is the
accepted offer.

SCALE: 1 of 35 apps on the whole OpenRoad purchase tape has a NULL UNIQUE_OFFER_KEY, so it is a
one-off, not a pattern. Worth re-checking if the book grows.

NOT the same class as [[wm-zy97pd]]. There, a v2 model_request exists and the model_response is
missing - a gateway/Experian failure surface. Here both request and response are present and
healthy; the failure is at post-loan booking and is caused by the client's payload. The only thing
the two share is that both were initially misdiagnosed as "never submitted" from a wrong JSON path.

## Next steps
1. Decide whether to recover the link. Options: a correction mapping this APP_ID to the real offer
   uuid (the value is knowable, which meets the corrections bar), or a fallback in the offers join
   that resolves OFFER_UUID against requestUuid + interest rate when the direct match fails. The
   correction is narrower and honest; the join fallback risks masking future instances.
2. Either way it should be raised with OpenRoad - they sent requestUuid as acceptedOfferUuid and a
   zero principalPurchasePrice, and their own booking call was rejected twice without anyone acting
   on it.
3. If recovered, anl/irr/anl_band/irr_band stop being "worse" for [[wm-skvqac]] and OpenRoad's
   count of columns below the Snowflake >= datastore bar drops from 5 to 1 (is_joint).

## Provenance
Read-only, 2026-08-25, PROD. Unscoped payload search on the uuid, RECURSIVE FLATTEN to locate its
json paths, LATERAL FLATTEN of the 19-offer array, purchase tape and silver.positions for the
funded terms.
