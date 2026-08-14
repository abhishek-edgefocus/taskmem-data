---
id: wm-etzegu
type: task
title: Alert on silent Oliv-ANL retarget fallback (Trishit ask 2026-07-27)
status: next
priority: p2
size: m
people: [Trishit]
tags: [northpond, dev-1445, alerting]
links: [parent:wm-j523sq, parent:wm-btu784]
created: 2026-07-27T14:05:01Z
updated: 2026-08-14T14:55:29Z
source: claude-code
label: Oliv retarget fallback alert
---

Trishit (Slack DM thread 2026-07-27 19:17-19:18 IST): the retarget in northpond_api_predictions falls back to k=1 (keeps our predictions) when an ANL is non-positive/corrupt; that fallback is currently SILENT. He wants: keep falling back (better than erroring), but fire an alert when it happens for a loan Oliv DID provide an ANL for.

Detection: loan has a silver.northpond_stmt_issuance_v2 row with ANL NOT NULL, but retarget fell back because v2.ANL<=0 OR payload:anl<=0.

Template = edgefocus/monitoring/marlette_purchase_tape_alerts.py (Snowflake check + STATE_TABLE idempotency + notifications.slack.send_message) registered as a MONITORING-group Dagster asset deps=[northpond_api_predictions], run in statements_northpond. Separate follow-up PR, not #6015 (which is in review).

Open Qs: which Slack channel; whether to also alert the 32 'Oliv ANL present but no gateway model response / not scored' loans. tags: northpond dev-1445 alerting

## Log
- 2026-07-27T14:57Z [claude-code] Decisions (2026-07-27): (1) Channel = NEW #northpond-data-monitoring (create it, invite bot + Trishit; no northpond channel exists today, only #best-egg-data-monitoring for Marlette). (2) Scope broadened per Abhishek: alert on ALL cases where k was not cleanly applied at full strength, categorized by reason -- (a) oliv_anl<=0, (b) our payload:anl<=0, (c) scaled default prob hit the cap>1, (d) hit floor<0 (defensive, expect 0), and likely (e) Oliv ANL present but loan not scored at all (32 no-model-response loans). EXCLUDE the expected no-Oliv-ANL back book (~717) = pure noise. Prepay is unscaled+unclamped now so no prepay category. Still planning, not implementing.
- 2026-07-28T17:39Z [claude-code] FIELD REPAIR + RECONCILE 2026-07-28. The item was malformed: 'next' had been written into the type field (type=next) while status was 'open', so it never appeared in a next/active view and had no priority, size, tags, people, parent or label. Set type=task, status=next, and filled in the rest from the body — the tags line at the end of the body ('northpond dev-1445 alerting') had been written as prose instead of as fields. Nothing about the work itself changed.
STATE CHECK: PR #6015, which the body says this must NOT be folded into, MERGED 2026-07-27 and DEV-1445 is Done — so the 'separate follow-up PR' constraint is now simply true rather than a sequencing worry, and this can be built whenever. Trishit's ask is still unimplemented; the 2026-07-27 decisions (new #northpond-data-monitoring channel, categorise by fallback reason, exclude the ~717 no-Oliv-ANL back book) stand.
- 2026-07-31T12:55Z [claude-code] PREMISE MAY BE OBSOLETE — CHECK BEFORE BUILDING (2026-07-31). This alert was scoped against the INLINE SQL retarget in northpond_api_predictions.py, which falls back to k=1 silently when an ANL is missing. Trishit's PR #6082 (APPROVED, open — see [[wm-g22j5e]]) REVERTS that inline retarget and gates the transform to api_version=1; exp retargeting moves into the oliv_exp_statement_model artifact, where the rule becomes target = max(oliv_anl if published else our_anl, 6.5%). That is a different failure mode: instead of silently keeping our own predictions at k=1, a missing Oliv ANL now falls back to our own ANL floored at 6.5%. So the thing to alert on changes shape, and the code location changes entirely. Do not build against the old path until #6082's fate is settled.
