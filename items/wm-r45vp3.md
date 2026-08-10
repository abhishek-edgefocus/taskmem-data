---
id: wm-r45vp3
type: project
title: AI billing to Slack (DEV-970)
status: active
tags: [ai-billing]
created: 2026-07-15T14:44Z
updated: 2026-08-10T14:50:13Z
source: dpx-tasks import
label: AI billing project
---

Visibility on AI tool spend alongside AWS in Slack

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-08-10T14:37Z [claude-code] Audited PR #5388 (DEV-970 2/2, Slack reporting). It is a DRAFT, stacked on abhishek/dev-970-ramp-ingestion, 17 files +879. Findings: (1) CONFLICTING - trial merge shows exactly one conflict, orchestration/definitions.py; branch is 12 commits behind its base. (2) Written against the PRE-rename schema: reads silver.ramp_transactions (gone, now silver.ramp_ai_transactions) in ramp_ai_expenses.py, its test, orchestration/assets/ramp_ai_billing.py (deps=["ramp_transactions"]), jobs/ramp_ai_billing_daily.py and terraform/snowflake/silver_ramp_ai_expenses.tf. (3) DESIGN OBSOLETE: silver/ramp_ai_vendors.py implements the rejected keyword waterfall (AI_PROVIDER_RULES, LIKE %anthropic%) and silver/ramp_ai_expenses.py filters silver to AI vendors - both redundant now that PR 1 lands only GL-5510 rows. (4) USELESS TESTS - exactly what Frank objected to: ramp_ai_expenses_test.py and gold/ramp_ai_spend_daily_test.py are 100 percent substring-on-SQL assertions (assert "GROUP BY" in sql.upper() etc), ramp_ai_vendors_test.py partly. Only send_ai_billing_report_test.py has real behavioural tests. (5) CI is stale (last run weeks old, integration tests skipping). PROPOSAL: delete silver/ramp_ai_vendors.py + silver/ramp_ai_expenses.py + their terraform and tests, and have gold.ramp_ai_spend_daily read silver.ramp_ai_transactions directly grouping by MERCHANT_NAME as PROVIDER - Ramp already normalises merchant_name (our 202 rows show exactly 4 clean values: Cursor, Anthropic, OpenAI, OpenWhispr). Awaiting Abhishek decision before rewriting.
- 2026-08-10T14:50Z [claude-code] Reworked PR #5388 per Abhishek decision to drop the silver layer. Merged the ingestion base in (one conflict, orchestration/definitions.py, resolved to keep the renamed ingest plus the reporting assets). DELETED silver/ramp_ai_vendors.py + test, silver/ramp_ai_expenses.py + test, gold/ramp_ai_spend_daily_test.py, terraform/snowflake/silver_ramp_ai_expenses.tf. REWROTE gold/ramp_ai_spend_daily.py to read silver.ramp_ai_transactions grouping MERCHANT_NAME as PROVIDER; assets/ramp_ai_billing.py now a single gold asset deps=[ramp_ai_transactions]; jobs/ramp_ai_billing_daily.py selects only the gold asset. send_ai_billing_report._ordered_providers no longer imports AI_PROVIDER_RULES - now orders by spend descending, ties on name (behaviour change, called out in the PR body). ADDED gold/ramp_ai_spend_daily_int_test.py using the repo generate_sql + execute_string + read _temp pattern - 3 passed in 31.7s against an ephemeral PR database. Dagster definitions load clean: ramp assets are ingest_ramp_ai_transactions, ramp_ai_transactions, ramp_ai_spend_daily (ramp_ai_expenses gone); all 4 jobs present. 3018 unit tests pass, ruff + mypy clean. Pushed 5b563621e; PR went CONFLICTING -> MERGEABLE, 17 files +879 -> 13 files +683 -2. PR description rewritten. Work done in worktree ~/claude-ws/dev970-pr2 on branch pr2-rework. STILL PENDING on 5388: it is a DRAFT, CI still running, and it cannot merge until #5880 does.
