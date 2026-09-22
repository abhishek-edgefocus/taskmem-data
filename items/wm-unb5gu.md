---
id: wm-unb5gu
type: task
title: Land the PagerDuty fan-out fix: drop `app` from group_by + missing-series hold on AWS rules
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T18:16:15Z
source: claude-code
---

Drafted 2026-09-22, NOT applied. Repo edgefocus/efp-k8s-gitops.
1) apps/sterling/grafana-alerting/alert-rules-app-errors.yaml, rule app-error-logged: group_by [alertname, app, subject, environment, ec2_tag_Name] -> [alertname, subject, environment, ec2_tag_Name]. Keep `app != ""` in the query filter and `app` in `sum by`.
2) alert-rules-aws-services.yaml, all 7 rules: add missing_series_evals_to_resolve: 60 beside the existing noDataState: OK / execErrState: KeepLast.
Measured effect over 2026-09-08..09-23: 699 -> 541 incidents (-158, 23%), no coverage loss.
Validate both against the Grafana provisioning API before merge — the file header warns an unknown enum fails the WHOLE alerting reload (Grafana 12.3.1).
Accepted cost: merged groups have empty CommonLabels.app, so the PD title drops the '- <app>' segment and efp.pd.group falls back to ec2_tag_Name.
Full reasoning + rejected alternatives: ~/notes/areas/observability/pagerduty-incident-fan-out.md. Evidence: wm-qtsgmv.

## Log
- 2026-09-22T18:16Z [claude-code] 2026-09-22: BLOCKED on validation — no draft PR opened. Patch is written and verified locally at dp:~/claude-ws/pd-dedup/efp-k8s-gitops (branch not created, nothing pushed, nothing committed).

WHY BLOCKED: cannot reach the sterling provisioning API. Exhausted:
- aws ssm get-parameter /grafana/ci-dagster-deploy-token -> AccessDenied (ssm:GetParameter, not just DescribeParameters) for user dexter-plus-ubuntu
- aws secretsmanager get-secret-value grafana_token -> AccessDenied
- no ~/.kube on dpx; /usr/local/bin/kubectl is an ARM aarch64 binary on an x86 box (unusable)
- sterling anonymous /api/v1/provisioning/alert-rules -> 401; anonymousEnabled not set
- dp:~/.grafana.env creds -> 401 password-auth.failed on sterling (they are legacy-only; deliberately did NOT validate against legacy)
- efp-k8s-gitops has NO CI that validates alert rules, so opening the PR would not validate either (checked .github; PR #123 merged today carries no API output in its body — the team's practice is reason-and-merge)
Sterling IS reachable: /api/health returns 200, version 12.3.1, commit 3a1c80ca7ce.

WHAT I NEED (any one):
(a) a Grafana service-account token for grafana.sterling.edgefocuspartners.com with alerting-read (Viewer + Alerting Rules Reader is enough for GET /api/v1/provisioning/alert-rules), dropped somewhere dpx can read e.g. ~/.grafana-sterling.env; or
(b) ssm:GetParameter granted to dexter-plus-ubuntu on /grafana/* ; or
(c) someone with access runs the two GETs and pastes the output.
Tracked as wm-g8mcv2.

PATCH READY (verified with yaml.safe_load; both files parse; resulting fields inspected):
- alert-rules-app-errors.yaml, app-error-logged: group_by ["alertname","app","subject","environment","ec2_tag_Name"] -> ["alertname","subject","environment","ec2_tag_Name"], + a 20-line comment explaining the wrapper double-logging, what stays load-bearing (app != "" filter, sum by), and the accepted cost.
- alert-rules-aws-services.yaml: missing_series_evals_to_resolve: 60 added to all 7 rules as instructed.
Scope held: no changes to populate_efp_stats.sh or custom_logging.py.

TWO THINGS TO RAISE BEFORE THIS SHIPS:
(1) THE 7-RULE HOLD IS WIDER THAN THE EVIDENCE. Incidents by aws rule over 09-08..09-23: SQS 26, RDS CPU high 3, RDS freeable memory low 3, and the other four fired ZERO times. Every query in that file is a filtered vector (`> threshold`), so missing-series is the NORMAL resolve path — a 1h hold therefore delays the all-clear by 1h on EVERY rule, including RDS CPU high where there is no measured repeat problem. Recommend narrowing to sqs-oldest-message-age only (the full -24 is there); awaiting Abhishek's call.
(2) MY BASELINE PREDATES PR #123. nakula-efp merged "hold Application error instances for 30h, not 12h" today 2026-09-22T15:24Z, changing missing_series_evals_to_resolve on the very rule being patched. My 699->541 replay measured the 12h regime. Decomposition: 71 of the -134 are same-second collapses (regime-independent); 63 are cross-time threading (regime-sensitive, and would likely INCREASE under a 30h hold since instances stay open longer). The -158 headline should be re-measured, or stated as "measured under the pre-#123 regime", before it goes in a PR body as proof.
