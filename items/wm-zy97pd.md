---
id: wm-zy97pd
type: task
title: 55 northpond balancesheet loans never hit the decisioning API (no model_request at all) — May/Jun 2026 100% unscored
status: next
priority: normal
size: s
tags: [northpond]
created: 2026-08-21T21:56:59Z
updated: 2026-08-21T21:57:03Z
source: claude-code
---

Found while validating DEV-1279 on 2026-08-21 (see wm-ch9wmr for the full query set).

On PROD.SILVER.POSITIONS AS_OF_DATE=2026-08-21, 55 northpond loans have no at_orig predicted cashflow, no silver.predictions row, and NO bronze.api_events of any type — not model_requests, not model_responses, not experian_request. They were never submitted for scoring at all, so this sits upstream of every cfframe/prediction issue.

Shape:
- fund=northpond_balancesheet, status=current on all 55
- originated 2026-05 (12), 2026-06 (28), 2026-07 (15); ~125,628 principal
- ANL and EF_SCORE NULL on all of them
- ids look like northpond_OLV125632xx with real APPLICATION_IDs

Coverage by month: May 0/12 scored, June 0/28, July 125/140, August 519/519. The two clean-miss months are May and June 2026; July is partial.

The question to settle: by design (a channel that bypasses EF decisioning) or a real submission gap? If by design, register it so coverage checks stop flagging it. The July partial overlaps the 2026-07-16→21 NorthPond API outage (wm-wvdxs4), but that outage cannot explain May and June.
