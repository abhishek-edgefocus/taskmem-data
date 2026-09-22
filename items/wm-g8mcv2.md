---
id: wm-g8mcv2
type: task
title: Get a sterling Grafana API token for dpx
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T17:57:17Z
source: claude-code
---

Found 2026-09-22 (wm-qtsgmv). dp:~/.grafana.env holds GRAFANA_USER/GRAFANA_PASSWORD for the LEGACY grafana.edgefocuspartners.com, which returns 200 with ZERO alert rules. grafana.sterling.edgefocuspartners.com rejects those creds (401 password-auth.failed). Consequence: alert rules can only be read from GitOps (edgefocus/efp-k8s-gitops @ apps/sterling/grafana-alerting/), and live alert state — firing instances, silences, rule health — cannot be read at all from dpx.
CI has one via SSM /grafana/ci-dagster-deploy-token, but dpx's IAM user (dexter-plus-ubuntu) is denied ssm:DescribeParameters.
Update the grafana-api-access memory once this is resolved.
