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
updated: 2026-07-16T11:20:04Z
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
