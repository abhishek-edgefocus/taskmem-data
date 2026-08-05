---
id: wm-3y3ckv
type: project
title: On-call / Errors backlog
status: active
tags: [oncall]
created: 2026-07-15T14:44Z
updated: 2026-08-05T16:43:22Z
source: dpx-tasks import
label: On-call errors backlog
---

Assigned ERROR-* and data-consistency issues

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-07-16T06:54Z [claude-code] Debugged recurring Experian errors in #errors -> wm-5qpdn3. Two distinct issues: (1) OAuth 'account in invalid state' 401s, spiked 07-12/13, zero since 07-14 = resolved; (2) still-firing Sentry EFP-ERRORS-AW is a catch-all masking the real Experian error body (~1/day, mostly HTTP 400 on bad pass-through input).
- 2026-07-16T07:05Z [claude-code] Refocused on the two alerts actually posted to #errors today (11:52 IST, EFP-ERRORS-1J8/1J9): transient IPv4 connect blip to Experian's Imperva edge, amplified by a 0.5s connect timeout and mislabelled 'Network is unreachable' by the IPv6 AAAA fallback. Reproduced. 1 app affected, recovered. -> wm-q3n9rf. (wm-5qpdn3 covers the separate, older EFP-ERRORS-AW catch-all.)
- 2026-08-05T16:43Z [claude-code] 2026-08-05: Pulled full ERROR team backlog from Linear (60 open issues) and clustered by root cause into 13 groups -> ~20 distinct causes. Largest: CloudWatch alarm noise (10, 7 are 'is now OK' recoveries that shouldn't be ticketed), Dagster asset failures (11), predictions pipeline (7), dumbledore datastore-generation (4: ERROR-1667/1668/1669/1670, all filed within 2h on 08-05 across marlette/happymoney/northpond/prosper = likely one shared cause, best first investigation), bureau connectivity (5), model serving (5), stale heartbeats (5). Duplicate pairs: 1367/1368, 84/85, 1615/1616, 425/885. Note ERROR-1621 = error_checker_sns heartbeat stale, i.e. the error checker itself may have gaps. Group overlaps with existing items: wm-s2f382 (Experian/northpond triage), wm-u52nd6 (DEV-1478 OAuth), wm-ufw7kj (DEV-1490 Clarity NULLs), wm-wvdxs4 (northpond API outage -> ERROR-1231).
