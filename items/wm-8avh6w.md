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
updated: 2026-09-03T16:02:03Z
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
- 2026-09-03T15:46Z [claude-code] 2026-09-03 Addressed his 5 comments on the freshness architecture artifact (https://claude.ai/code/artifact/42a74c01-910a-4b4e-be63-99bf7138ab17) and republished to the same URL.

1. Byline block ("we dont need this") — Author/Date/Status/Project meta row removed from the masthead, plus its CSS and the mobile override. Thread replied to and RESOLVED (it was the only one activated for Claude).
2. "check-in §1.1, §5.1" — he could not tell what the section numbers referred to. Stripped every unresolvable cross-reference to the check-in's numbering (§1.1/§5.1 in scope, "§5 of the check-in" in audience, "(§1.3)" in the risk table header); the dated 2026-08-27 reference stays because it is identifiable.
3. "we are gonna start the dashboard from scratch and not modify any existing dashboard" — added an explicit line opening §2: neither existing dashboard is being modified, the pane is new, and the two are read only to establish what it must do differently.
4. "should we also monitor the dagster job status ... so that we are aware about silent failures?" — ADOPTED into the design rather than left as an open question. Added: a Producing asset field to the series model (§6.1); a new §6.6; an In-scope bullet; a producing-job-state row in the dashboard sketch (§9); a silent-failure row in the risk table (§10).
5. "we can directly link the dashboard ... need not highlight that there exists a similar or standalone dashboard" (dictated, read phonetically) — §2.1 now just hyperlinks the Data health dashboard; dropped the folder / created / last-edited recital and the mention of the duplicate standalone copy at /d/638061b6. Same treatment applied to the two legacy datastore dashboards in §3.
6. "We should look into what is the right cadence for every platform. I will do for most of them. It is daily." — §7 now states daily as the default a series takes when nothing is declared, frames the per-platform work as finding the EXCEPTIONS, and records that he is setting most of them himself.

NEW PROD EVIDENCE GATHERED FOR §6.6 (read-only, prod Dagster GraphQL, 2026-09-03): statements_* runs in the window 2026-08-31 22:33 -> 2026-09-03 15:36 UTC = 30 FAILURE / 55 SUCCESS. statements_northpond 7 failed / 0 succeeded; statements_lc 3 / 0. Two platforms with no successful statement run at all in the window and nothing on any dashboard saying so.

CORRECTION TO [[wm-hjbt5a]] — DO NOT keep citing the 2026-08-12 finding as current. All 13 statement sensors now read RUNNING in prod, including openroad, lc, upstart, innovate and foursight, which that audit found STOPPED with zero ticks. The sensor half of that item has been fixed since; the job-failure half has not. I checked before writing the number into a document going to Scott, which is the only reason it did not go out stale.

DESIGN POINT WORTH KEEPING: run status is necessary but NOT sufficient, and §6.6 says so. The counter-example is [[wm-8uyfnw]] — best_est_projections_at_orig materialized SUCCESSFULLY in prod on 2026-08-31 and wrote zero northpond rows. A green run over unmoved data is exactly what a purely orchestration-based monitor calls healthy, so the pane carries both checks in the same row. Flagged inline as a dated, not-re-verified observation.

STILL OPEN: 4 of the 5 threads are NOT activated for Claude, so they cannot be replied to or resolved from here and remain open on the artifact even though all 4 are addressed. He can resolve them in the artifact view, or reply with Send to Claude if he wants them answered in thread.
- 2026-09-03T15:48Z [claude-code] 2026-09-03: the artifact was edited and republished elsewhere (version 1788450351-f80c) while this session held the previous copy. Diffed and synced DOWN rather than overwriting — ~/data-freshness-architecture.md and the local HTML now match the live page; pre-sync copies kept as .bak-pre-sync. The edits added a whole missing dimension the first draft did not have: a new section 6.6 'Did the job run, and did it write anything?', arguing that a data-only freshness check infers the pipeline one-directionally and slowly, so each series must also carry its producing Dagster asset. Evidence added: prod statements_* runs 2026-08-31 22:33 to 2026-09-03 15:36 UTC — statements_northpond 7 failed / 0 succeeded, statements_lc 3/0, upgrade 5/13, happymoney 4/24, anchored 3/3, foursight 3/3, total 30 failed / 55 succeeded; two platforms with zero successful statement runs in the window and nothing on any dashboard saying so. This corroborates [[wm-hjbt5a]] (5 sensors never enabled, 3 jobs failing every tick) from a different angle. The counter-example added alongside it: 2026-08-31 best_est_projections_at_orig materialised SUCCESSFULLY in prod and wrote zero northpond rows, gold.predicted_cashflows_mob likewise — green run, stale table, no error. That is [[wm-8uyfnw]], which dates the no-op from 2026-08-27, so the doc's 08-31 is an observation of an ongoing condition rather than its onset — worth tightening if the section is revisited. Other edits: byline block dropped from the masthead; Grafana uids replaced with real links; meeting-note section references (s1.3, s5, s1.1) stripped throughout, so the doc no longer cites the private check-in by section; a 'working assumption is daily' default added to section 7; a 'pipeline that fails silently' row added to the section 10 risk table; dashboard sketch gained a producing-job-state panel; appendix updated on both sides. Section 2 also gained an explicit line that neither existing thing is being modified and the pane is new-build.
- 2026-09-03T15:56Z [claude-code] 2026-09-03: Built an architecture visualization of Scott's 4-PR freshness stack, read from the head branch scott/data-freshness-5-asset (not from the PR bodies). Published at https://claude.ai/code/artifact/024b72cd-d632-4c49-a7ed-7b64a094b358 ('Freshness Stack Teardown'). Five hand-drawn figures: the stack chain and what each PR holds; the full hourly runtime flow; the expected-as-of-date clock (due_by_hour_utc, delivery_lag_days, business-day roll, the three bands); the S3 StartAfter backlog probe; and the derives_from cap. Plus the SLA band table, a gold.data_freshness row anatomy for both check kinds, and the registry broken down by platform.

NUMBERS CORRECTED AGAINST THE 2026-09-02 LOG ENTRY. Counted from the branch on 2026-09-03: the registry declares 120 series, not 145 - 58 statement, 54 standardized, 8 gateway, across the same 12 platforms. #6586 is +1221 across 7 files, not +1182. The PR was last updated 2026-09-03T15:24Z, so either the registry shrank since the 2026-09-01 Grafana evaluation (145 rows in DEV_SCOTT.GOLD.DATA_FRESHNESS) or the dashboard was reading a superseded run. Do not requote 145 without re-checking. #6588 (the 3/5 split for gold.data_freshness) is CLOSED and folded into #6589; the stack is now strictly 6586 -> 6587 -> 6589 -> 6590.

FIVE SEAMS THE TEARDOWN SURFACES, all from the code, none of them defects in what it claims to do:
1. A gateway channel receiving NO traffic reads as current - gateway.channel_backlogs returns CAUGHT_UP (0.0h) for an absent prefix. The check measures ingestion lag, not arrival. Nothing in the registry asks 'has this channel produced anything today?', which is the exact shape of DEV-1690 (Anchored API data not being ingested), the motivating example on Scott's own project.
2. record_results() catches, logs and returns 0; the asset stays green. The append-passing-rows design makes a gap in the table meaningful, but only if something outside the stack alerts on the gap. Nothing in the stack does.
3. Only 22 of the 54 standardized series declare derives_from, so 32 are graded against the calendar alone - silver.predictions, silver.credit_pulls and gold.offers_daily declare none anywhere. Expect first-week amber noise concentrated there.
4. gold.data_freshness grows unbounded: 120 rows/hour is ~1.05M rows/year, and data_retention_time_in_days = 1 is Time Travel, not a row TTL. No clustering key. Every Grafana panel needs an EVALUATED_AT predicate from day one.
5. Nothing reconciles registry.py against reality: a statement_type string that does not match bronze.statement_files reads as permanently overdue rather than as a typo. A one-off diff of the registry's 58 statement keys against distinct (PLATFORM, STATEMENT_TYPE) in that table would settle it.

RELEVANCE TO THE OWNERSHIP QUESTION (Q1 of the architecture doc): the stack does NOT cover the producing-job dimension that section 6.6 of the doc argues for - there is no Dagster run-state check anywhere in it, so the [[wm-8uyfnw]] failure mode (green run, zero rows written) is invisible to it. That is the substantive gap between Scott's spike and the documented design, and the concrete thing to raise with him rather than a general build-vs-adopt argument.
- 2026-09-03T16:02Z [claude-code] 2026-09-03 (2) REWRITE after Abhishek spoke to Scott. The four stacked PRs #6586-#6590 were shared DELIBERATELY, as work Scott started to help him get going, with "feel free to discard any or all of it". So the doc's job changed from "here is my design" to "here is Scott's stack, what I'd keep, what I'd change, what's missing from both". ~/data-freshness-architecture.md rewritten and the artifact republished.

EVERY REVIEW FINDING WAS RE-VERIFIED AGAINST PROD/REPO MYSELF, not taken on trust. Confirmed: the cherry-picked decay chart; the live efp.checkins registry; gateway_last_order.py; the Missing Files Summary panel; Scott's dashboard panels; forward-dated as_of_date; figure's last rows_added; DEV-439 and DEV-1690 histories; no holiday mask; no GRAFANA_READER in terraform; the /d/638061b6 uid.

FIVE PLACES THE REVIEWER WAS WRONG OR IMPRECISE, corrected in the doc with my own numbers:
1. Parsing rules: total is 230 and ignore is 116, NOT 231/117. Headline 47 of 114 (41%) is right. The reviewer also said to KEEP the per-platform table - but its denominators were the same bad all-rules totals, so I replaced them with monitorable counts (northpond 5/23 -> 5/10, lc 3/20 -> 3/15, intex 1/2 -> 1/1, figure 0/9 -> 0/6, anchored 0/7 -> 0/6).
2. efp.checkins has NO status column, so "14 in error" cannot come from it. The real analogue I computed: 76 of 182 non-test heartbeats are currently past their declared interval. That is a better argument anyway - it shows a declared list still rots without pruning (case 4.4).
3. "user is populated" overstates: 108 of 182 (59%).
4. figure "everything since is rows_added_empty" overstates: there is exactly ONE file after 2024-12-31, a single rows_added_empty on 2025-01-01, then nothing. Stronger conclusion, not weaker.
5. "sofi weekly and marlette monthly at 9 and 25 days" did not reproduce. My verified worked example: sofi/purchase_tape 7 days (weekly band 9/16 = fresh), marlette/debt_sale 33 days (monthly band 32/40 = late not overdue), sofi/positions 1 day.
Also pipeline_watermarks read 500/347/66 today vs the reviewer's 500/361/66 - which is itself the point about timestamping it.

TWO DESIGN POSITIONS I DROPPED, both to Scott:
- Per-series threshold tuning -> his five named SLA bands. ~145 series x 2 numbers = 290 unreviewable magic numbers; five bands fit on a screen and are pinned by a test. EXCEPTION I kept and argued: the gateway, because gateway_last_order.py already carries 8 per-channel thresholds spanning 8 minutes to 16 hours - a 120x spread no single band survives. His API_LATE/MAX_BACKLOG_HOURS are global 2.5/3.5.
- Blocked-upstream SUPPRESSION -> his cap_for. Suppression produces the false green it was meant to prevent: an unGRADED series hides a silver table broken on its own account. cap_for lowers the expectation, records capped_to, and still grades. He was right.

THREE FALSE-GREEN CASES UNHANDLED IN BOTH DESIGNS, now the core of the doc (§4):
- Forward-dated as_of_date: happymoney 2026-09-09 (6 days ahead), sofi 2026-09-04. Permanent green that survives the feed stopping. Rule: ahead of expected = unknown, not current.
- Partial evaluation carry-forward: a cycle that fails on one target leaves yesterday's green. Rule: unreadable = overdue, never carried forward.
- Stale registration with no end_date (figure, and 76 of the checkins rows).

ACTIONS THIS SURFACED THAT ARE NOT DOC EDITS:
- lc is a LIVE INCIDENT with no ticket: silver positions AND realized_cashflows_calendar_month both 2026-08-24, 10 days behind, vs <=3 for every other active platform. statements_lc 3 failures / 0 successes in the window. Needs a ticket opened.
- DEV-439 is a question for FRANK or ESHAN, not Scott - he never touched it. Backlog -> Duplicate -> Canceled two seconds apart on 2026-04-12, created by Frank, assigned Eshan. That is a cleanup pass, not a rejection of Dagster freshness policies.
- Questions went 8 -> 6: Q1 (are the PRs a spike) deleted as answered, figure answered in §6.1, GRAFANA_READER and DEV-439 resolved out.
