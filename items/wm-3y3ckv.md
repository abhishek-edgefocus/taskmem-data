---
id: wm-3y3ckv
type: project
title: On-call / Errors backlog
status: active
tags: [oncall]
created: 2026-07-15T14:44Z
updated: 2026-07-16T06:54:49Z
source: dpx-tasks import
---

Assigned ERROR-* and data-consistency issues

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-07-16T06:54Z [claude-code] Debugged recurring Experian errors in #errors -> wm-5qpdn3. Two distinct issues: (1) OAuth 'account in invalid state' 401s, spiked 07-12/13, zero since 07-14 = resolved; (2) still-firing Sentry EFP-ERRORS-AW is a catch-all masking the real Experian error body (~1/day, mostly HTTP 400 on bad pass-through input).
