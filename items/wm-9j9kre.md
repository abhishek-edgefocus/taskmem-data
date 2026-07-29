---
id: wm-9j9kre
type: task
title: PR-proof Snowflake notebooks via ~/bin/snb on dpx
status: done
tags: [tooling, snowflake]
created: 2026-07-29T13:15:41Z
updated: 2026-07-29T13:52:19Z
source: claude-code
---

snb <NAME> <file.sql> builds a Snowflake notebook from a .sql file split on '-- @cell: title' markers, PUTs it to @DEV_ABHISHEK.SCRATCH.PR_NOTEBOOKS, creates the notebook, validates with a headless 'execute notebook', prints the Snowsight URL. Purpose: open one link, run cells sequentially, screenshot each for PR descriptions. Creds come from ~/repos/efp/.env (SNOWFLAKE_*); the PAT in ~/.snowflake/connections.toml is expired.

## Log
- 2026-07-29T13:52Z [claude-code] Pivoted from notebooks to sqlshot: ~/bin/sqlshot on the Mac + ~/bin/sqlrun.py on dpx. Runs each query in a .sql file (split on '-- @cell: title', with a '-- @setup' block for 'use database'), then renders SQL + real results to PNG via headless Chrome at 2x. Footer carries account/role/warehouse/db.schema/query_id/timestamp so a reviewer can verify in query history. Verified against PROD.SILVER.TRANSACTIONS and an error case. Worksheets have no public API and notebook downloads omit outputs, hence the render-it-myself approach.
