---
id: wm-xd886y
type: task
title: Exclude dexterplus from the 'Fleet host CPU high' Grafana rule
status: open
links: [relates:wm-qtsgmv]
created: 2026-09-22T17:57:05Z
updated: 2026-09-22T17:57:17Z
source: claude-code
---

Found 2026-09-22 while investigating PD fan-out (wm-qtsgmv). 22 of 32 'Dev box CPU saturated (dexterplus)' incidents on PD service efp-devbox overlap in time with a 'Fleet host CPU high' incident for the same host on efp-devops — two rules describing one condition, paging two services. 29 fleet-CPU incidents on dexterplus in 15 days.
app-error-logged already excludes dexterplus on BOTH ec2_tag_Name and hostname; alert-rules-fleet.yaml's Fleet host CPU high does not. The repo comment in notification-policies.yaml shows the Slack half of this was already fixed by deleting the ec2_tag_Name=dexterplus route — the PagerDuty half was missed.
NOT fixable with PD Alert Grouping: grouping is per-service and these are two services.
