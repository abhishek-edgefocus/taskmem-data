---
id: wm-h3dvpa
type: followup
title: Reply to Abhijeet: confirm OPs currently use API predictions only (EDGEX EF scoring thread)
status: waiting
size: xs
due: 2026-07-17
waiting_on: Abhishek
nudge: 2026-07-17
people: [Abhijeet]
tags: [northpond, needs-reply]
links: [parent:wm-j523sq]
refs: [slack=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1784139879078909?thread_ts=1784139879.078909&cid=C06RMEK095G]
created: 2026-07-15T21:14:10Z
updated: 2026-07-16T11:29:01Z
source: claude-code
---

Abhijeet in #north-pond-tech (2026-07-15 23:54 IST), re the upcoming EDGEX deal: EF scoring and stored OPs must come from the final northpond model, disregarding API predictions. He asked Abhishek directly: (a) is it correct that the current setup only uses API predictions for the OPs? (b) once the northpond model is ready, set it up for the EF score calculation. Thread since: Nakula — pipeline will likely need dedup preferring source='s3' over source='api'; Trishit — the model is ready to provide EF grades, but ANL computation is owned by Eric's team, so grades come via them. Abhishek has not replied yet.

## Next steps
1. Reply in Abhijeet's thread: confirm (or correct) that OPs currently come from API predictions only.
2. Point at the tracked implementation item for the setup work (child of this one).

## Links
- Abhijeet's ask (thread): https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1784139879078909?thread_ts=1784139879.078909&cid=C06RMEK095G
- Project: wm-j523sq (NorthPond Data Ingestion)

## Log
- 2026-07-15T21:14Z [claude-code] captured retroactively: a prior session read Abhijeet's messages but did not track this unanswered ask — protocol gap now fixed in AGENTS.md (reading messages counts as intake)
- 2026-07-16T11:19Z [claude-code] Verified Abhijeet's premise against PROD (read-only), CONFIRMED: northpond OPs come from API predictions only. PROD.SILVER.PREDICTIONS northpond = 27,828 rows / 773 loans, 100% source='api', prediction_type='at_orig', as_of 2024-10-09..2026-07-15; zero source='s3' rows. Cross-check: s3 predictions exist only for marlette/sofi/upgrade/prosper/happymoney (5 platforms, 42.8M rows) — northpond has never landed an s3 prediction. Chain: silver.predictions -> predicted_cashflows_history (northpond 27,828 rows/773 loans, all at_orig) -> silver.ef_scores (750 northpond loans; ef_scores takes MIN(GENERATION_TS) earliest generation per EFP_ID, ~23 loans drop on the EF_SCORE IS NOT NULL filter). Code: edgefocus/transformations/silver/predictions/northpond_api_predictions.py (issuance + bronze.api_events via APPLICATION_UUID, 'api' AS SOURCE, PREDICTION_TYPE='at_orig'); s3_predictions.py is platform-generic (driven by bronze.prediction_files) so northpond needs no new transform type - only a producer writing prediction parquet + Nakula's dedup. Reply drafted for Abhishek; not sent (user sends Slack themselves).
- 2026-07-16T11:20Z [claude-code] Verification + draft reply complete; waiting on Abhishek to post the reply in Abhijeet's thread (agent does not send Slack).
- 2026-07-16T11:29Z [claude-code] Fact-checked a proposed draft reply against the code (PROD read-only). Core claim CONFIRMED (northpond OPs = api-only). But 2 claims in that draft are wrong/incomplete and would be visible to Abhijeet/Nakula: (1) 'a loan with both api and s3 at_orig would flow through twice and DOUBLE-COUNT in ANL' — mechanism is wrong. generate_anl_from_cashflows_sql (positions_utils.py:103) computes ANL = NET_LOSS*12/WEIGHTED_PRIN, a ratio of two SUMs over GROUP BY EFP_ID. If both curves are present BOTH numerator and denominator inflate, so ANL is NOT 2x — it silently becomes a principal-weighted BLEND of the api and s3 ANLs. Dedup is still required (silent blend is arguably worse than an obvious 2x), but the failure mode must be stated correctly. (2) 'EF scoring already filters to at_orig, so the model output will drive the EF score' — the at_orig filter is real (positions_utils.py:88) but the conclusion doesn't follow.
- 2026-07-16T11:29Z [claude-code] The load-bearing gap the draft misses: silver.ef_scores is LOCKED to the earliest generation — populate_ef_scores.py:50 passes earliest_generation_only=True, i.e. QUALIFY GENERATION_TS = MIN(GENERATION_TS) OVER (PARTITION BY EFP_ID). Every existing northpond loan (773 loans, api at_orig since 2024-10-09) therefore already has an EARLIER api generation, which WINS over any later s3 model generation. So the s3 model would be IGNORED by ef_scores for existing loans, not preferred. Adding s3-over-api precedence in silver.predictions does NOT fix this on its own, because predicted_cashflows_history retains the already-materialised api generations. Only genuinely-new loans (s3 landing first) get the model score for free. Needs an explicit backfill/purge of api-derived history generations, or a source-precedence rule inside the ef_scores generation pick.
