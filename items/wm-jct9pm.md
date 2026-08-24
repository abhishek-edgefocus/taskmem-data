---
id: wm-jct9pm
type: task
title: Create a Viewer service-account token for the sterling Grafana so agent sessions can read it
status: next
priority: p3
size: s
tags: [grafana, dpx, tooling]
created: 2026-08-24T18:24:04Z
updated: 2026-08-24T18:24:21Z
source: claude-code
---

grafana.sterling.edgefocuspartners.com is a SEPARATE Grafana from grafana.edgefocuspartners.com.
The creds in ~/.grafana.env on dpx are for the latter and get "Invalid username or password"
(messageId password-auth.failed) against sterling. Sterling has no anonymous access at all —
even /api/frontend/settings returns 401. Version 12.3.1, so API keys are deprecated; the right
mechanism is a service account token.

Surfaced 2026-08-24 while investigating the northpond_loan_fl Experian 401s ([[wm-u52nd6]]).
The dashboard Abhishek started from — /d/efp-production-traffic/production-traffic-endpoint-lb,
var-targetgroup=northpond-loan-fl-production — lives only on sterling. It is an ALB target-group
view, so that investigation was completed against CloudWatch directly and NOTHING was blocked.
This item exists so the next session does not hit the same wall.

STEPS (Abhishek does these; the token must never go through a chat transcript):
1. https://grafana.sterling.edgefocuspartners.com/org/serviceaccounts
   (Administration -> Users and access -> Service accounts)
2. Add service account, name e.g. claude-code-readonly, role VIEWER.
   Viewer is sufficient: it can read dashboards and run /api/ds/query. Do not grant Editor/Admin.
3. Add service account token, set an expiry, Generate, copy (shown once, starts glsa_).
4. On dpx, keep it out of shell history:
     umask 077; cat > ~/.grafana-sterling.env    <paste 2 lines, Ctrl-D>
       GRAFANA_STERLING_URL=https://grafana.sterling.edgefocuspartners.com
       GRAFANA_STERLING_TOKEN=glsa_...
5. Verify:
     set -a; . ~/.grafana-sterling.env; set +a
     curl -s -H "Authorization: Bearer $GRAFANA_STERLING_TOKEN" \
       "$GRAFANA_STERLING_URL/api/search?query=production-traffic"

IF THE SERVICE ACCOUNTS PAGE IS NOT VISIBLE: Abhishek is not an org admin on sterling (his admin
on the main Grafana does not carry over) — needs whoever operates that instance to create it.

STILL UNKNOWN once access exists: what datasources sterling has. The main Grafana's dashboards
use a mysql datasource (uid LR_rCfanz, host grafana.edgefocuspartners.net); sterling's are
unread. Worth recording in ~/notes when someone can finally see them.
