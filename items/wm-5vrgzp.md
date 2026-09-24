---
id: wm-5vrgzp
type: task
title: Confirm Kabeer owns the recurring StandardizedPositions/marlette datastore failure (daily since 2026-09-19)
status: next
priority: p2
size: xs
due: 2026-09-23
tags: [oncall, pagerduty, marlette]
links: [relates:wm-w98jug]
created: 2026-09-22T17:26:27Z
updated: 2026-09-24T12:09:38Z
source: claude-code
---

## Log
- 2026-09-22T17:26Z [claude-code] Attribution is verbal only — Nakula told Abhishek that Kabeer is looking into it. Slack search of #alert-team-coder and all channels since 09-14 found NO message from Kabeer (or anyone) claiming it; no human replies on the alert threads at all. So this is uncorroborated. Evidence it is unresolved: [DatastoreStandardizedPositions][marlette] resolved 8x across 09-19/20/21 and fired again 09-22T04:04Z (PD #1370/#1369, acked by Nakula). Whatever Kabeer is doing has not stopped it, and each day mints a fresh incident pair onto whoever is on-call.
- 2026-09-24T12:09Z [pd-1455] SUPERSEDED as framed. The recurrence is NOT the bug Kabeer fixed: #6680 (ordering, 2 ignore-list loans) is deployed and working. The nightly failures since 09-18 have a different root cause — 105 unscorable edgex20261NN loans from Marlette's header-only originations files. See [[wm-uc6eaz]]. Kabeer is still the natural owner of the add_ef_score gate, but there is nothing for him to 'still be looking into' on the old cause.
