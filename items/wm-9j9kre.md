---
id: wm-9j9kre
type: task
title: PR-proof Snowflake notebooks via ~/bin/snb on dpx
status: done
tags: [tooling, snowflake]
created: 2026-07-29T13:15:41Z
updated: 2026-07-29T13:15:41Z
source: claude-code
---

snb <NAME> <file.sql> builds a Snowflake notebook from a .sql file split on '-- @cell: title' markers, PUTs it to @DEV_ABHISHEK.SCRATCH.PR_NOTEBOOKS, creates the notebook, validates with a headless 'execute notebook', prints the Snowsight URL. Purpose: open one link, run cells sequentially, screenshot each for PR descriptions. Creds come from ~/repos/efp/.env (SNOWFLAKE_*); the PAT in ~/.snowflake/connections.toml is expired.
