---
id: wm-htwfmr
type: bug
title: Fix gateway_platforms parquet coercion crash blocking anchored_auto_indirect model_requests (PD #1445)
status: next
priority: high
tags: [efp, anchored, oncall, pagerduty]
created: 2026-09-24T11:23:32Z
updated: 2026-09-24T11:23:32Z
source: pd-1446
label: Fix gateway_platforms parquet coercion crash
estimate: <1h
---

PD #1445 (https://edgefocuspartners.pagerduty.com/incidents/Q2NPIG0ARZR3Z8) — open and still firing daily.

bin/historical_model_inputs/gateway/gateway_platforms.py:107

    requests = requests.replace(["<NA>", ""], np.NaN)

raises TypeError: Cannot compare types 'ndarray(dtype=object)' and 'str' when any column holds list/ndarray cells — pandas replace() does an elementwise compare against the scalar '<NA>'.

Failed 2026-09-22 and 2026-09-23 at 13:00 PT on [anchored_auto_indirect][model_requests] with "Number of gateway logs to add: 3" — those 3 gateway logs are still unadded. Also hit [anchored_auto_indirect][point_metrics] once on 2026-09-07. Other channels (innovate_auto_refi, marlette_loan_td, prosper_loan_td, openroad_auto_refi) all logged "Nothing to add" so they never reached the coercion.

Runs daily at 13:00 PT; will crash again until fixed. Log: /efs/logs/dumbledore/historical_model_inputs_gateway_platforms.log (traceback at line 127020).

Likely fix: skip object columns whose cells are list/ndarray before the replace, or apply the replace only to scalar columns. Confirm which column carries the array first.

Found while investigating PD #1446/#1448 (see [[wm-w98jug]]) — same channel, but a parallel feed, NOT the upstream of that failure.


## Environment
- taskmem: 326cb1c
- reported by: pd-1446
- host: ip-192-168-1-6.ap-south-1.compute.internal
- when: 2026-09-24T11:23:32Z
