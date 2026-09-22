---
id: wm-8mur32
type: task
title: Drain or retire STAGING-gateway-ingest-dlq — stuck 186h
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T17:57:17Z
source: claude-code
---

Found 2026-09-22 (wm-qtsgmv). All 26 'SQS oldest message older than a day' incidents in the 15-day sample are this ONE queue; oldest message aged 169h -> 186h across the window. The alerting fix (missing-series hold) collapses 26 incidents to 2 but does NOT drain the queue. Someone needs to decide whether anything still consumes it.
