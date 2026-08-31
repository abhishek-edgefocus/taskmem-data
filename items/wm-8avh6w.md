---
id: wm-8avh6w
type: task
title: Lead Scott's new 'platform data freshness' project — single pane of glass for stale vs fresh data
status: next
priority: p2
size: l
due: 2026-09-04
people: [Scott, Sean]
tags: [grafana, data-quality, freshness]
links: [relates:wm-4s2sad, relates:wm-hjbt5a]
refs: [DEV-freshness=https://linear.app/edge-focus/project/improve-visibility-into-platform-data-freshness-087906c438c6]
created: 2026-08-31T15:49:24Z
updated: 2026-08-31T15:50:32Z
source: slack
label: platform data freshness
---

Scott Morgan created this Linear project on 2026-08-27T15:43Z and sent it to Abhishek by DM the
same evening (22:59 IST, D0BPKHF65UK): "As promised: Improve visibility into platform data
freshness". Abhishek replied "Thanks! Will look into this next week." — that week is now, w/c
2026-08-31.

**Abhishek is the project LEAD**, not a contributor. Verified on the Linear project 2026-08-31:
lead = Abhishek Doshi, team = Development, status = Planned, priority = Medium, initiative =
"Build & Maintain Data / Modeling Edge". There is **no target date set on the project and no
target date on any milestone** — so nothing here is late yet, and setting those dates is
arguably the first thing the lead does.

THE PROBLEM AS SCOTT STATES IT, verbatim from the project description: "Right now it is
difficult to answer 'is the data for all platforms up to date'? To do so, you would have to
know, at a minimum, what Snowflake tables to look at and know the frequency that various
sources are expected to arrive in. **We want a single pane of glass where a user can see,
within seconds, which platforms have fresh data and which have stale data.**" It must also
cover API data from the platforms, and the description points at DEV-1690 ("Anchored API data
is not being ingested") as the motivating example.

THREE MILESTONES, all 0%: (1) Reviewable architecture document, (2) Live dashboard,
(3) [Optional] Staleness alerting. The architecture doc is the gate — it is what "reviewable"
means, and it comes before any dashboard work.

WHY THIS LANDS ON GROUND ABHISHEK ALREADY OWNS. This is not a greenfield ask; several open
items are fragments of exactly this problem, and they are the raw material for the
architecture doc rather than competing work:

- [[wm-4s2sad]] — the datastore-vs-Snowflake comparison job has been dead since 2026-07-20
  across all 11 platforms, and that item already records the key insight this project is
  built on: "a board that stops updating currently looks identical to a board with no
  problems." That is Scott's thesis, discovered independently a month earlier.
- [[wm-hjbt5a]] — 5 platform statement sensors were never enabled in prod Dagster and 3
  platform jobs fail every tick. Those are precisely the platforms a freshness pane would
  light up red on day one.
- [[wm-7f5974]] — northpond has had no working last-order freshness alarm since 2026-01-16,
  because the empty branch `continue`s before the staleness check. A worked example of the
  failure mode: an alarm that exists, passes, and checks nothing.
- [[wm-etzegu]] — Trishit's 2026-07-27 ask for an alert on the silent Oliv-ANL retarget
  fallback is the same shape as milestone 3.
- [[wm-b9uq8f]] — setting a MonitoringSchedule on northpond_purchase_tape_v0_csv is the
  per-source cadence mechanism this project would generalise.

## Next steps
1. Open the Linear project and set a target date on it and on the architecture-doc milestone —
   as lead, the absent dates are yours to fill, and Scott left them blank.
2. Ask Scott (DM D0BPKHF65UK, where he sent it) what "within seconds" means concretely: who is
   the user of the pane — him, ops, the on-call engineer — and is the expected arrival cadence
   per source something we already hold anywhere, or does the project have to establish it.
3. Read DEV-1690 (Anchored API data not being ingested) — it is the example Scott chose, so
   the doc should be able to explain how the pane would have caught it.
4. Draft the architecture document off the items above rather than from scratch: the
   MonitoringSchedule mechanism, the dead comparison job, the northpond alarm that checks
   nothing, and the sensors that were never enabled are four real freshness-blindness modes
   already diagnosed with evidence.
5. Decompose this item into children once the doc's shape is agreed — it is sized l and is a
   container, not a task.

## Links
- Linear project — https://linear.app/edge-focus/project/improve-visibility-into-platform-data-freshness-087906c438c6
- Scott's DM handing it over — https://edgefocuspartners.slack.com/archives/D0BPKHF65UK/p1787851796623989
- DEV-1690, the motivating example — https://linear.app/edge-focus/issue/DEV-1690/anchored-api-data-is-not-being-ingested
