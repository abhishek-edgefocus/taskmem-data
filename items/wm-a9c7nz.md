---
id: wm-a9c7nz
type: task
title: Build EF-vs-Oliv prediction comparison dashboard (ENL/ANL scatter, CGL, CNL)
status: open
priority: p3
tags: [northpond]
links: [relates:wm-c5jytx, parent:wm-3sxcre]
created: 2026-07-21T12:19:22Z
updated: 2026-08-22T09:57:35Z
source: claude-code
---

Action item assigned to Abhishek on the 2026-07-16 "Oliv Origination Predictions Handoff" call (raw transcript, 00:42:34). Captured 2026-07-21 from the meeting doc -- it had never been tracked anywhere.

Trishit's ask: once EDGEX deployment starts, build dashboards tracking OUR internal ANL / ENL projections against OLIV's predictions, so deviation between the two models is visible. He specifically suggested a SCATTER PLOT of ENL versus ANL per loan, to see whether the two track a straight line or diverge heavily.

Metrics Abhishek confirmed on the call: ENL, CGL, CNL, plus cashflows.

Purpose stated by Trishit: this is the feedback loop for recalibration. Once realized delinquency data arrives, the deviation pattern determines when and how to recalibrate the internal best-estimate prediction model. It is also what an EDGEX investor asks for -- "what were our origination predictions and where are we tracking in the realized data".

## Dependencies
- Needs Oliv's ANL landed per loan (see [[wm-c5jytx]]) -- nothing to plot until then.
- Needs our own ENL/CGL/CNL projections for the same loans, which is the curve-generation question in [[wm-9s2mwd]].
- Distinct from [[wm-rp2y23]] (EdgeX-2026-1NN Grafana dashboards + promoting the NorthPond monitoring dashboard); this is a model-vs-model comparison view, not portfolio monitoring.

## Timing
Trishit framed it as "when we start to build going forward, whenever the deployment starts to come in" -- i.e. not before the ANL feed exists. Not urgent this week, but it is a real committed deliverable and should not silently disappear.

## Log
- 2026-07-21T12:34Z [claude-code] Dropped to p3 2026-07-21 (dashboard work deferred to next week). Independently blocked anyway: nothing to plot until Oliv's ANL lands per loan via wm-c5jytx.
- 2026-08-22T09:57Z [claude-code] 2026-08-22: built the first cut. Grafana test dashboard "[DEV-1446] Model comparison — EF vs Oliv (CNL/CGL/ANL/cash flows)" is live at /d/dev1446-ef-vs-oliv/ in Testing Dashboards > Devs > Abhishek. 18 panels. All 24 queries validated against PROD for all four northpond funds, then re-run through Grafana's own snowflake datasource to confirm the panels actually resolve. Builder + validator kept at dp:~/claude-ws/dev-1446/ (panels.py, build.py, validate.py, verify.py); build.py is idempotent on uid dev1446-ef-vs-oliv.

Data sources settled — this was the real unknown:
- OUR per-loan ANL is silver.positions.ANL, byte-identical to silver.ef_scores.EF_ANL (611/611 rows match to 0.0).
- OLIV's is silver.northpond_stmt_issuance_v2.ANL / CGL / ICCM_SCORE.
- They join cleanly on positions.APPLICATION_ID = issuance_v2.APPLICATION_UUID (1414/1414 on the latest snapshot; positions.POSITION_ID = OLIV_LOAN_NUMBER works equally well).
- Our CGL/CNL curve by MOB is gold.predicted_cashflows_mob (PREDICTION_TYPE='at_orig') — it carries CGL and CNL as literal columns, no derivation needed.
- Cash flows: gold.predicted_cashflows_calendar_month vs gold.realized_cashflows_calendar_month_daily; realized MOB curves from silver.realized_cashflows_from_purchase.

The dependency on wm-c5jytx is therefore satisfied: Oliv's ANL IS landed per loan (8,032 of 28,836 issuance_v2 rows populated).

Headline result on edgex20261NN (265 loans carrying both models): the ANLs agree — EF 11.06% vs Oliv 10.96%, +10bps — but the CGLs do not: EF 12.77% vs Oliv 14.91%, -213bps. Gross-to-net is EF 1.10 vs Oliv 1.36. The recovery assumption is the entire disagreement. Direct evidence for wm-v7apt2.

Not covered, by absence of data rather than by choice: Oliv publishes no cash-flow projection, so the cash-flow row is ours-vs-realized with Oliv's lifetime gross loss drawn as a flat reference. Said so on the dashboard's caveats panel rather than implying a comparison that does not exist.

Next: Abhishek reviews the test dashboard, then it gets promoted manually (GrafanaClient cannot write outside Testing Dashboards).
