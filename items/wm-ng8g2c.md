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
updated: 2026-07-27T18:02:10Z
source: dpx-tasks #11
label: Ramp account setup
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #11
- 2026-07-27T18:02Z [claude-code] Blocks live testing of PR #5880: no Ramp account/API creds exist yet - /dagster/prod/ramp_client_id and _secret both return ParameterNotFound, and PR #5880 never added the terraform ssm_parameters.tf entries its own docstring references. Any end-to-end Ramp ingest test waits on this.
