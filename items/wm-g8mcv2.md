---
id: wm-g8mcv2
type: task
title: Get a sterling Grafana API token for dpx
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T18:16:15Z
source: claude-code
---

Found 2026-09-22 (wm-qtsgmv). dp:~/.grafana.env holds GRAFANA_USER/GRAFANA_PASSWORD for the LEGACY grafana.edgefocuspartners.com, which returns 200 with ZERO alert rules. grafana.sterling.edgefocuspartners.com rejects those creds (401 password-auth.failed). Consequence: alert rules can only be read from GitOps (edgefocus/efp-k8s-gitops @ apps/sterling/grafana-alerting/), and live alert state — firing instances, silences, rule health — cannot be read at all from dpx.
CI has one via SSM /grafana/ci-dagster-deploy-token, but dpx's IAM user (dexter-plus-ubuntu) is denied ssm:DescribeParameters.
Update the grafana-api-access memory once this is resolved.

## Log
- 2026-09-22T18:16Z [claude-code] 2026-09-22: now BLOCKING wm-unb5gu (the fan-out fix PR). Confirmed exhausted from dpx: ssm:GetParameter denied (not just DescribeParameters), secretsmanager:GetSecretValue denied, no ~/.kube, kubectl is ARM on an x86 box, sterling anonymous provisioning 401, legacy .grafana.env creds 401 on sterling, and efp-k8s-gitops has no rule-validating CI. Sterling health endpoint IS open: 200, v12.3.1, commit 3a1c80ca7ce. Cheapest unblock is a Grafana service account token (Viewer + Alerting Rules Reader) at dp:~/.grafana-sterling.env.
