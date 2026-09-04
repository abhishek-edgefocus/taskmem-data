---
id: wm-vv3htk
type: followup
title: Review Scott's PII-hash PR #6541 for the NorthPond + OpenRoad API endpoints
status: next
priority: p1
size: s
due: 2026-09-05
people: [Scott]
tags: [northpond, openroad, needs-reply, api-health]
refs: [thread=https://edgefocuspartners.slack.com/archives/G01LRBTFG4U/p1788525464625349?thread_ts=1788375642.243529]
created: 2026-09-04T13:35:31Z
updated: 2026-09-04T13:35:31Z
source: claude-code
---

Scott merged a feature that securely hashes certain PII values and includes them in the
endpoint transaction payloads (so repeat borrowers can be detected across applications).
The Anchored API already integrates with it and is confirmed working in prod.

PR https://github.com/edgefocus/efp/pull/6541 does the same for **all other API endpoints**.
Scott posted in #team-devs (thread parent ts 1788375642.243529) asking every platform owner
to review the change for their own platform, and said explicitly:
**"I'll wait for everyone's confirmation before merging."** He sent a reminder naming
Abhishek on 2026-09-04 18:07 IST — so this is now blocking his merge.

## Next steps
1. Read PR #6541 for the northpond endpoints (`northpond_loan_fl`, `northpond_exp_loan_fl`)
   and the openroad endpoint — check which fields get hashed and that nothing the platform
   relies on downstream changes shape.
2. Reply in the #team-devs thread confirming (or flagging) for NorthPond and OpenRoad.
