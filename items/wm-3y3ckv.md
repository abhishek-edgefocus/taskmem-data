---
id: wm-3y3ckv
type: project
title: On-call / Errors backlog
status: active
tags: [oncall]
created: 2026-07-15T14:44Z
updated: 2026-07-16T07:05:14Z
source: dpx-tasks import
---

Assigned ERROR-* and data-consistency issues

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-07-16T06:54Z [claude-code] Debugged recurring Experian errors in #errors -> wm-5qpdn3. Two distinct issues: (1) OAuth 'account in invalid state' 401s, spiked 07-12/13, zero since 07-14 = resolved; (2) still-firing Sentry EFP-ERRORS-AW is a catch-all masking the real Experian error body (~1/day, mostly HTTP 400 on bad pass-through input).
- 2026-07-16T07:05Z [claude-code] Refocused on the two alerts actually posted to #errors today (11:52 IST, EFP-ERRORS-1J8/1J9): transient IPv4 connect blip to Experian's Imperva edge, amplified by a 0.5s connect timeout and mislabelled 'Network is unreachable' by the IPv6 AAAA fallback. Reproduced. 1 app affected, recovered. -> wm-q3n9rf. (wm-5qpdn3 covers the separate, older EFP-ERRORS-AW catch-all.)
