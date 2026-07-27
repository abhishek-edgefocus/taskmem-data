---
id: wm-etzegu
type: next
title: Alert on silent Oliv-ANL retarget fallback (Trishit ask 2026-07-27)
status: open
created: 2026-07-27T14:05:01Z
updated: 2026-07-27T14:05:01Z
source: claude-code
---

Trishit (Slack DM thread 2026-07-27 19:17-19:18 IST): the retarget in northpond_api_predictions falls back to k=1 (keeps our predictions) when an ANL is non-positive/corrupt; that fallback is currently SILENT. He wants: keep falling back (better than erroring), but fire an alert when it happens for a loan Oliv DID provide an ANL for.

Detection: loan has a silver.northpond_stmt_issuance_v2 row with ANL NOT NULL, but retarget fell back because v2.ANL<=0 OR payload:anl<=0.

Template = edgefocus/monitoring/marlette_purchase_tape_alerts.py (Snowflake check + STATE_TABLE idempotency + notifications.slack.send_message) registered as a MONITORING-group Dagster asset deps=[northpond_api_predictions], run in statements_northpond. Separate follow-up PR, not #6015 (which is in review).

Open Qs: which Slack channel; whether to also alert the 32 'Oliv ANL present but no gateway model response / not scored' loans. tags: northpond dev-1445 alerting
