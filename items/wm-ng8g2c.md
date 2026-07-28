---
id: wm-ng8g2c
type: task
title: Create Ramp account using the automations Google account
status: done
priority: p2
size: s
tags: [ramp, account-setup, ai-billing]
links: [parent:wm-gcdq6k]
created: 2026-07-14
updated: 2026-07-28T10:36:15Z
source: dpx-tasks #11
label: Ramp account setup
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #11
- 2026-07-27T18:02Z [claude-code] Blocks live testing of PR #5880: no Ramp account/API creds exist yet - /dagster/prod/ramp_client_id and _secret both return ParameterNotFound, and PR #5880 never added the terraform ssm_parameters.tf entries its own docstring references. Any end-to-end Ramp ingest test waits on this.
- 2026-07-27T20:12Z [claude-code] Prod access for DEV-970 is a hand-off item: prod Dagster ECS task definitions live in the separate efp-infra repo (stacks/dagster-ecs/<env>, discovered via the /efp-infra/dagster/<env>/* SSM contract read by .github/workflows/_deploy-dagster.yml), not in efp. For the merged job to authenticate in prod, RAMP_CLIENT_ID/RAMP_CLIENT_SECRET must be injected into the prod dagster task the same way GMAIL_CLIENT_ID/SLACK_BOT_TOKEN are, or stored in Secrets Manager as ramp_client_id/ramp_client_secret with the task role allowed to read them. Cannot be done or verified from dpx (IAM denies ECS + Secrets Manager + /efp-infra SSM).
- 2026-07-28T10:18Z [claude-code] Cloned edgefocus/efp-infrastructure to dpx ~/repos/efp-infrastructure, branch abhishek/dev-970-ramp-credentials. Added ramp_client_id + ramp_client_secret as prod-only SSM SecureStrings (PLACEHOLDER_UPDATE_IN_CONSOLE + lifecycle.ignore_changes, mirroring mercury_api_key) in modules/dagster_ecs/resource-ssm-parameters.tf, plus 6 secrets entries in resource-ecs.tf across the daemon, run and code_server task definitions (NOT webserver, NOT the agent task - same placement as mercury). Also added the 2 rows to the terraform-docs table in modules/dagster_ecs/README.md since CI runs terraform_docs via pre-commit. Deliberately did NOT touch stacks/dagster-ecs/prod/bin/import.sh - that is a one-time importer for pre-existing AWS resources and these two do not exist yet, so terraform must create them. terraform fmt clean. UNCOMMITTED, not pushed.
- 2026-07-28T10:36Z [claude-code] Closing as superseded, not done-as-written. The Apr-14 ticket TODO said create a new Ramp account via the automations Google account; the 2026-05-26 Linear thread settled it differently - Fernando/Frank created a Developer app with client-credentials inside the EXISTING company Ramp account. Those credentials have been on dpx since 2026-07-01 and authenticate fine against the live API (verified today). Nothing left to create.
