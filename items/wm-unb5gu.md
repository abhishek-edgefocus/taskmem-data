---
id: wm-unb5gu
type: task
title: Land the PagerDuty fan-out fix: drop `app` from group_by + missing-series hold on AWS rules
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T17:57:17Z
source: claude-code
---

Drafted 2026-09-22, NOT applied. Repo edgefocus/efp-k8s-gitops.
1) apps/sterling/grafana-alerting/alert-rules-app-errors.yaml, rule app-error-logged: group_by [alertname, app, subject, environment, ec2_tag_Name] -> [alertname, subject, environment, ec2_tag_Name]. Keep `app != ""` in the query filter and `app` in `sum by`.
2) alert-rules-aws-services.yaml, all 7 rules: add missing_series_evals_to_resolve: 60 beside the existing noDataState: OK / execErrState: KeepLast.
Measured effect over 2026-09-08..09-23: 699 -> 541 incidents (-158, 23%), no coverage loss.
Validate both against the Grafana provisioning API before merge — the file header warns an unknown enum fails the WHOLE alerting reload (Grafana 12.3.1).
Accepted cost: merged groups have empty CommonLabels.app, so the PD title drops the '- <app>' segment and efp.pd.group falls back to ec2_tag_Name.
Full reasoning + rejected alternatives: ~/notes/areas/observability/pagerduty-incident-fan-out.md. Evidence: wm-qtsgmv.
