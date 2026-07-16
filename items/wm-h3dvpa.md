---
id: wm-h3dvpa
type: followup
title: Reply to Abhijeet: confirm OPs currently use API predictions only (EDGEX EF scoring thread)
status: active
size: xs
due: 2026-07-17
people: [Abhijeet]
tags: [northpond, needs-reply]
links: [parent:wm-j523sq]
refs: [slack=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1784139879078909?thread_ts=1784139879.078909&cid=C06RMEK095G]
created: 2026-07-15T21:14:10Z
updated: 2026-07-16T11:19:58Z
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
