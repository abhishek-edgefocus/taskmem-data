---
id: wm-prm54n
type: task
title: Deprecate OpenRoad datastores by 2026-08-03 (milestone at 0%)
status: next
priority: p1
size: l
due: 2026-08-03
people: [Abhijeet]
tags: [openroad, datastores]
links: [parent:wm-su6q4d, relates:wm-bvqkhh, relates:wm-tvjjgw]
created: 2026-07-29T15:33:30Z
updated: 2026-07-29T15:33:30Z
source: claude-code
label: OpenRoad datastore deprecation
---

Abhijeet asked directly in DM 2026-07-29 19:50 IST (D0B2A3WSJ5N): "openroad deprecate
datastores on track to be done by 3rd aug?" — so he is actively tracking this to a date.

CONFIRMED IN LINEAR 2026-07-29: OpenRoad Data Ingestion project milestones —
- Validate positions   — 100%, target 2026-07-08 (hit)
- Validate predictions —  25%, target 2026-07-31  (= DEV-1331, its only issue, now In
                                                    Review; [[wm-bvqkhh]])
- **Deprecate datastores — 0%, target 2026-08-03**  <- this item
Project lead is Abhijeet. The deprecation milestone has not started.

WHAT ABHISHEK TOLD HIM (same exchange):
- The openroad predictions PR is up and review-requested from Abhijeet ("baghto").
- Abhijeet: "tech urlay na phakta?" (is that the only thing left?) — Abhishek: "Ekda check
  karava lagel I think mostly ho" (need to check once, I think mostly yes). **That check is
  an open action and is the first step here** — the answer given was hedged, and the
  milestone reads 0%, which does not match "mostly only that left".
- Abhijeet then asked whether BEP was added — it is not; CMOP and BEP are outstanding for
  BOTH platforms (OpenRoad and NorthPond). Tracked separately.

SEQUENCING: predictions validation (2026-07-31) gates this (2026-08-03) — three days apart,
and the predictions PR still needs Abhijeet's approval, then prod re-materialisation and a
notebook re-run before DEV-1331 can close. That is a tight chain; if the PR sits, 08-03
slips.

Adjacent risk on the NorthPond side, same theme: [[wm-tvjjgw]] (legacy northpond datastore
silently starving as Oliv moves files).
