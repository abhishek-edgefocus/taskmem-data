---
id: wm-ng8g2c
type: task
title: Create Ramp account using the automations Google account
status: next
priority: p2
size: s
tags: [ramp, account-setup, ai-billing]
links: [parent:wm-gcdq6k]
created: 2026-07-14
updated: 2026-07-27T20:12:55Z
source: dpx-tasks #11
label: Ramp account setup
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #11
- 2026-07-27T18:02Z [claude-code] Blocks live testing of PR #5880: no Ramp account/API creds exist yet - /dagster/prod/ramp_client_id and _secret both return ParameterNotFound, and PR #5880 never added the terraform ssm_parameters.tf entries its own docstring references. Any end-to-end Ramp ingest test waits on this.
- 2026-07-27T20:12Z [claude-code] Prod access for DEV-970 is a hand-off item: prod Dagster ECS task definitions live in the separate efp-infra repo (stacks/dagster-ecs/<env>, discovered via the /efp-infra/dagster/<env>/* SSM contract read by .github/workflows/_deploy-dagster.yml), not in efp. For the merged job to authenticate in prod, RAMP_CLIENT_ID/RAMP_CLIENT_SECRET must be injected into the prod dagster task the same way GMAIL_CLIENT_ID/SLACK_BOT_TOKEN are, or stored in Secrets Manager as ramp_client_id/ramp_client_secret with the task role allowed to read them. Cannot be done or verified from dpx (IAM denies ECS + Secrets Manager + /efp-infra SSM).
