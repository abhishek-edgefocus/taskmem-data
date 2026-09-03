---
id: wm-8avh6w
type: task
title: Lead Scott's new 'platform data freshness' project — single pane of glass for stale vs fresh data
status: active
priority: p2
size: l
due: 2026-09-04
people: [Scott, Sean]
tags: [grafana, data-quality, freshness]
links: [relates:wm-4s2sad, relates:wm-hjbt5a]
refs: [DEV-freshness=https://linear.app/edge-focus/project/improve-visibility-into-platform-data-freshness-087906c438c6]
created: 2026-08-31T15:49:24Z
updated: 2026-09-03T12:11:33Z
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

## Log
- 2026-09-02T13:15Z [claude-code] Investigated 2026-09-02. The project is no longer greenfield: Scott built the whole thing himself between 2026-08-31 and 2026-09-01 and left it as a 4-PR DRAFT stack — #6586 expectations/registry/lateness (+1182), #6587 gateway backlog probe (+353), #6589 evaluator + results writer + terraform gold.data_freshness (+929), #6590 hourly Dagster asset (+75). Two earlier single PRs (#6559, #6561) were closed and re-split. All four are drafts, zero reviewers requested, empty bodies, no Linear ticket linked. He also built the Grafana dashboard 'Data freshness' (uid d626cb04-fa4d-4d28-bbef-ae9f5fa60f29, Testing Dashboards, v11, created 2026-09-01) reading DEV_SCOTT.GOLD.DATA_FRESHNESS — 145 declared series across 12 platforms, last evaluated 2026-09-01 12:44 (manual, the hourly asset is still in the draft PR). Registry declares anchored, foursight, happymoney, innovate, lc, marlette, northpond, openroad, prosper, sofi, upgrade, upstart — figure and intex are absent. So the lead's job is review + land + promote + document, not design. Abhijeet's dashboard (the one he shared) is the older, weaker prototype: panel 'Snowflake table freshness' on 'Data health' (uid frdwmfh) = max(as_of_date) over 5 silver tables with flat 2/7/8-day thresholds, no per-source cadence, no API coverage, no bronze/file-arrival — it is the same panel as his standalone dashboard uid 638061b6 from 2026-06-26.
- 2026-09-03T11:48Z [claude-code] CORRECTION to yesterday's read, after seeing the 2026-08-27 Scott/Abhishek weekly check-in notes (~17 min). The notes are explicit that ABHISHEK builds this, and that requirements come first: 'The dashboard work will be documented as a project/ticket with more detailed requirements... Build the dashboard once the project is documented' and 'expected scope relatively small, approximately one week or less'. Decisive line: 'The work is also considered a useful opportunity to gain broader exposure to other platforms and understand how their data ingestion works' — that framing only makes sense if he does the building. So yesterday's 'review + land Scott's stack' recommendation was wrong as a default; the stack was never discussed with him. Confirmed by Slack: the DM D0BPKHF65UK ends at 2026-08-27 23:00 with 'Will look into this next week' and Scott has said NOTHING about the 4 PRs since. Linear project still has ZERO issues and no dates as of 2026-09-03, unchanged since 2026-08-28. So Scott's #6586/6587/6589/6590 are an unannounced private spike, not a handoff. FOUR THINGS THE NOTES PIN DOWN THAT THE PROJECT DESCRIPTION DOES NOT: (1) The audience is platform DEVELOPERS doing a 20-30 min morning routine (notes s5.3), not ops and not Scott — that is the answer to the 'who is the user of the pane' question this item had open. (2) The existing config Scott means by 'expected lag/frequency settings... not consistently populated or adopted across all platforms' (s1.1) is MonitoringSchedule on parsing rules — 47 of 157 rules carry one, and anchored/figure/foursight/openroad have zero. Populating it is part of the project. (3) The stated reference model is the OLD DATASTORE staleness dashboard + scripts (s1.2) — worth finding before designing. (4) The 'daily alerts already being received' that lack an at-a-glance view (s1.2) are statement_file_alerts.py, the Sentry + Slack digest. Also: Scott's own guardrail is the trust risk (s1.3) — 'a simplistic implementation could result in misleading freshness information... lead people to stop using it' — which is exactly why Abhijeet's max(as_of_date) panel is not the answer. Prior art: DEV-439 'Implement Freshness Policies for BRONZE.STATEMENT_ROWS' (Frank, 2025-11-30, assigned Eshan, CANCELED) tried this via Dagster asset freshness policies with deadline_cron.
- 2026-09-03T12:11Z [claude-code] Milestone 1 drafted 2026-09-03. Doc at ~/data-freshness-architecture.md (source of truth, local Mac) and published for Scott at https://claude.ai/code/artifact/42a74c01-910a-4b4e-be63-99bf7138ab17 (title 'Data Freshness Architecture'). FOUND THE s1.2 PRECEDENT Scott referred to: two mechanisms, both still in the repo. (a) Grafana 'Dashboard: Datastore Positions Errors' (/d/-AlfQAu4z, 2023-06-21) and 'Dashboard: Datastore Cfframe Errors' (/d/IJVMuXhSk, 2024-02-16), folder 'Company: Edge Focus', MySQL-backed, populated by lib/efp/stats/grafana_tables/grafana_tables_datastore_{positions,cfframe}_errors.py. Three carry-forward ideas: freshness materialised into a dedicated system_datastore_* metadata table rather than computed live; the 'High Level Summary' panel = one row per channel, max(error_count/total_count) as Status, sorted worst-first (that IS the single-pane pattern); and errors_definitions giving every code a human-readable meaning. (b) THE CLOSER PRECEDENT: efp.checkins + bin/monitoring/heartbeat_checker.py — create(name, expected_checkin_seconds, platform, user), checker flags now-last_updated > expected and Slacks the named owner. Declared expectation living with the monitored thing, as a number, with an owner. Could not verify it still runs: mysql-ohio does not resolve from dpx, and the StatsEFP copy has only 3 junk 2022 rows and no user column. KILLER EVIDENCE for the doc: efp.errors_datastore_positions is still written daily but distinct channels per as_of_date went 25,25,25,25,25,22,18,1 over 2026-08-26..09-02 — channels that drop out simply stop appearing rather than going red, so 09-01 looked as healthy as 08-30 while covering 7 fewer channels. That is the concrete proof of the false-green failure mode, and it drives the doc's central requirement: rows must come from a declared list of what should exist, never from what is present in the data. Doc asks Scott 8 questions; Q1 is the ownership question about his 4 draft PRs.
