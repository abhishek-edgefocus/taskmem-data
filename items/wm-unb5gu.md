---
id: wm-unb5gu
type: task
title: Land the PagerDuty fan-out fix: drop `app` from group_by + missing-series hold on AWS rules
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-23T20:07:06Z
source: claude-code
---

Drafted 2026-09-22, NOT applied. Repo edgefocus/efp-k8s-gitops.
1) apps/sterling/grafana-alerting/alert-rules-app-errors.yaml, rule app-error-logged: group_by [alertname, app, subject, environment, ec2_tag_Name] -> [alertname, subject, environment, ec2_tag_Name]. Keep `app != ""` in the query filter and `app` in `sum by`.
2) alert-rules-aws-services.yaml, all 7 rules: add missing_series_evals_to_resolve: 60 beside the existing noDataState: OK / execErrState: KeepLast.
Measured effect over 2026-09-08..09-23: 699 -> 541 incidents (-158, 23%), no coverage loss.
Validate both against the Grafana provisioning API before merge — the file header warns an unknown enum fails the WHOLE alerting reload (Grafana 12.3.1).
Accepted cost: merged groups have empty CommonLabels.app, so the PD title drops the '- <app>' segment and efp.pd.group falls back to ec2_tag_Name.
Full reasoning + rejected alternatives: ~/notes/areas/observability/pagerduty-incident-fan-out.md. Evidence: wm-qtsgmv.

## Log
- 2026-09-22T18:16Z [claude-code] 2026-09-22: BLOCKED on validation — no draft PR opened. Patch is written and verified locally at dp:~/claude-ws/pd-dedup/efp-k8s-gitops (branch not created, nothing pushed, nothing committed).

WHY BLOCKED: cannot reach the sterling provisioning API. Exhausted:
- aws ssm get-parameter /grafana/ci-dagster-deploy-token -> AccessDenied (ssm:GetParameter, not just DescribeParameters) for user dexter-plus-ubuntu
- aws secretsmanager get-secret-value grafana_token -> AccessDenied
- no ~/.kube on dpx; /usr/local/bin/kubectl is an ARM aarch64 binary on an x86 box (unusable)
- sterling anonymous /api/v1/provisioning/alert-rules -> 401; anonymousEnabled not set
- dp:~/.grafana.env creds -> 401 password-auth.failed on sterling (they are legacy-only; deliberately did NOT validate against legacy)
- efp-k8s-gitops has NO CI that validates alert rules, so opening the PR would not validate either (checked .github; PR #123 merged today carries no API output in its body — the team's practice is reason-and-merge)
Sterling IS reachable: /api/health returns 200, version 12.3.1, commit 3a1c80ca7ce.

WHAT I NEED (any one):
(a) a Grafana service-account token for grafana.sterling.edgefocuspartners.com with alerting-read (Viewer + Alerting Rules Reader is enough for GET /api/v1/provisioning/alert-rules), dropped somewhere dpx can read e.g. ~/.grafana-sterling.env; or
(b) ssm:GetParameter granted to dexter-plus-ubuntu on /grafana/* ; or
(c) someone with access runs the two GETs and pastes the output.
Tracked as wm-g8mcv2.

PATCH READY (verified with yaml.safe_load; both files parse; resulting fields inspected):
- alert-rules-app-errors.yaml, app-error-logged: group_by ["alertname","app","subject","environment","ec2_tag_Name"] -> ["alertname","subject","environment","ec2_tag_Name"], + a 20-line comment explaining the wrapper double-logging, what stays load-bearing (app != "" filter, sum by), and the accepted cost.
- alert-rules-aws-services.yaml: missing_series_evals_to_resolve: 60 added to all 7 rules as instructed.
Scope held: no changes to populate_efp_stats.sh or custom_logging.py.

TWO THINGS TO RAISE BEFORE THIS SHIPS:
(1) THE 7-RULE HOLD IS WIDER THAN THE EVIDENCE. Incidents by aws rule over 09-08..09-23: SQS 26, RDS CPU high 3, RDS freeable memory low 3, and the other four fired ZERO times. Every query in that file is a filtered vector (`> threshold`), so missing-series is the NORMAL resolve path — a 1h hold therefore delays the all-clear by 1h on EVERY rule, including RDS CPU high where there is no measured repeat problem. Recommend narrowing to sqs-oldest-message-age only (the full -24 is there); awaiting Abhishek's call.
(2) MY BASELINE PREDATES PR #123. nakula-efp merged "hold Application error instances for 30h, not 12h" today 2026-09-22T15:24Z, changing missing_series_evals_to_resolve on the very rule being patched. My 699->541 replay measured the 12h regime. Decomposition: 71 of the -134 are same-second collapses (regime-independent); 63 are cross-time threading (regime-sensitive, and would likely INCREASE under a 30h hold since instances stay open longer). The -158 headline should be re-measured, or stated as "measured under the pre-#123 regime", before it goes in a PR body as proof.
- 2026-09-23T15:02Z [pd-alert-manager] 2026-09-23: checked the PagerDuty side of the fan-out. efp-coder (PRTG9L9) has ZERO alert-grouping settings configured — browse_alert_grouping returns []. Its service orchestration only assigns priority (critical->P1, error->P2 in/off hours, catch_all->P3); no grouping, no suppression. So PD creates one incident per alert, 1:1 — every incident checked has exactly 1 alert. All 23 open arrive through a single integration (P3OPR0Q Grafana Events API v2) from just 3 Grafana rules: app-error-logged (17 of 23: 9 dumbledore prod + 8 sandbox), dagster-error-logged (5), sqs-oldest-message (1). dedup_key is a sha256 over the whole Grafana label set incl. app AND subject, which is why two error messages from one app split into two incidents. PD already receives but ignores event_class ('Application error'/'Dagster error logged'), service_group (the app name) and source_component ('app-errors') — all usable as content-based grouping fields. KEY: this is a second, independent lever that needs NO Grafana/sterling access, so it is not blocked by the token gap holding wm-qtsgmv. Caveat: content-based alert grouping is a paid-tier PD feature; plan level unverified. Grouping would cut the count but would NOT fix stuck-open incidents (#1397 never got a resolve event) — that still needs the group_by/missing-series patch.
- 2026-09-23T20:07Z [pd-alert-manager] 2026-09-23 ~20:00Z: caught a mass auto-resolve that proves the resolve_by_absence flaw, with a clean control. Board went 28 -> 11 from two unrelated causes. (1) Abhishek manually resolved 10 between 18:04-19:16Z: #1436 #1437 (TU pair) and the sandbox sweep #1414 #1415 #1416 #1418 #1420 #1421 #1431 #1439. (2) Grafana auto-resolved 12 in a 27-second burst at 19:54:31-19:54:58Z (#1370 #1390 #1397 #1401 #1402 #1403 #1404 #1407 #1411 #1419 #1443) plus #1430 at 20:00:55 - every one of them from the app-error-logged rule, none from any other rule. That burst is NOT recovery. Proof: (a) #1390's AWS Batch job is still status FAILED 'Host EC2 terminated' with no newer warehouse_pred job queued, and generate_datastores_ubuntu last errored 15:05Z today; (b) #1419 collate_parquets resolved 19:54:57Z, wrote a fresh ERROR at 19:59:10Z, and re-fired as NEW incident #1444 at 20:05Z - ten minutes after closing; (c) all three reconcile jobs errored AGAIN tonight at 19:00:15 / 19:08:53 / 19:10:13Z, i.e. BEFORE the resolve. MECHANISM: the rule fires on '1 ERROR line(s) in the last 30m' with resolve_by_absence=true, so a nightly job that errors once at ~19:00 has an empty 30m window by ~19:40 and Grafana emits a resolve every single night whether or not anything was fixed. The alert answers 'did an error line appear in the last 30 minutes', not 'is this asset healthy'. This is the strongest single argument for the missing-series/hold patch: without it the board self-clears nightly and real breakage (a FAILED batch job) closes itself silently.
