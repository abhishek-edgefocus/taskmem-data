---
id: wm-etzegu
type: next
title: Alert on silent Oliv-ANL retarget fallback (Trishit ask 2026-07-27)
status: open
created: 2026-07-27T14:05:01Z
updated: 2026-07-27T14:57:01Z
source: claude-code
---

Trishit (Slack DM thread 2026-07-27 19:17-19:18 IST): the retarget in northpond_api_predictions falls back to k=1 (keeps our predictions) when an ANL is non-positive/corrupt; that fallback is currently SILENT. He wants: keep falling back (better than erroring), but fire an alert when it happens for a loan Oliv DID provide an ANL for.

Detection: loan has a silver.northpond_stmt_issuance_v2 row with ANL NOT NULL, but retarget fell back because v2.ANL<=0 OR payload:anl<=0.

Template = edgefocus/monitoring/marlette_purchase_tape_alerts.py (Snowflake check + STATE_TABLE idempotency + notifications.slack.send_message) registered as a MONITORING-group Dagster asset deps=[northpond_api_predictions], run in statements_northpond. Separate follow-up PR, not #6015 (which is in review).

Open Qs: which Slack channel; whether to also alert the 32 'Oliv ANL present but no gateway model response / not scored' loans. tags: northpond dev-1445 alerting

## Log
- 2026-07-27T14:57Z [claude-code] Decisions (2026-07-27): (1) Channel = NEW #northpond-data-monitoring (create it, invite bot + Trishit; no northpond channel exists today, only #best-egg-data-monitoring for Marlette). (2) Scope broadened per Abhishek: alert on ALL cases where k was not cleanly applied at full strength, categorized by reason -- (a) oliv_anl<=0, (b) our payload:anl<=0, (c) scaled default prob hit the cap>1, (d) hit floor<0 (defensive, expect 0), and likely (e) Oliv ANL present but loan not scored at all (32 no-model-response loans). EXCLUDE the expected no-Oliv-ANL back book (~717) = pure noise. Prepay is unscaled+unclamped now so no prepay category. Still planning, not implementing.
