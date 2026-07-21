---
id: wm-a9c7nz
type: task
title: Build EF-vs-Oliv prediction comparison dashboard (ENL/ANL scatter, CGL, CNL)
status: open
priority: p3
tags: [northpond]
links: [parent:wm-j523sq, relates:wm-c5jytx]
created: 2026-07-21T12:19:22Z
updated: 2026-07-21T12:34:14Z
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
