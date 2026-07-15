---
id: wm-c5jytx
type: task
title: Set up northpond model for EDGEX EF scoring — at_orig predictions into silver.predicted_cashflows
status: inbox
size: l
people: [Abhijeet, Trishit, Nakula]
tags: [northpond]
links: [parent:wm-h3dvpa]
refs: [slack=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1784139879078909?thread_ts=1784139879.078909&cid=C06RMEK095G]
created: 2026-07-15T21:14:11Z
updated: 2026-07-15T21:14:11Z
source: claude-code
---

From Abhijeet's EDGEX ask (thread below): once the final northpond model is ready, EF score calculation must use it instead of API predictions, storing the secondary-model predictions with prediction_type='at_orig' in silver.predicted_cashflows — similar to the forward-flow prediction pipeline used for other programs. Thread facts: Trishit says the model is ready for EF grades but ANL computation is owned by Eric's team (grades delivered via them); Nakula flags that the pipeline will need dedup preferring source='s3' over source='api'. Design can start now; execution depends on the grades-delivery path from Eric's team.

## Next steps
1. First answer Abhijeet's confirmation question (parent item wm-h3dvpa).
2. Review the forward-flow prediction pipeline for other programs as the template.
3. Design the ingestion: northpond-model predictions -> silver.predicted_cashflows with prediction_type='at_orig', including Nakula's dedup (prefer source='s3' over 'api').
4. Coordinate with Trishit / Eric's team on how EF grades + ANL outputs will be delivered.

## Links
- Abhijeet's ask (thread): https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1784139879078909?thread_ts=1784139879.078909&cid=C06RMEK095G
- Parent (the reply owed): wm-h3dvpa · Project: wm-j523sq
