---
id: wm-6yqsjy
type: followup
title: Report back to Kabeer + Nakula on the 4-5 OpenRoad prediction-error tickets assigned 2026-09-08
status: open
priority: p1
size: s
due: 2026-09-09
people: [kabeer, nakula]
tags: [needs-reply, slack, openroad, errors, oncall]
links: [related:wm-jr5bup]
refs: [dm=https://edgefocuspartners.slack.com/archives/C0C08E97EDC/p1788870172899589]
created: 2026-09-09T13:12:38Z
updated: 2026-09-11T14:26:12Z
source: slack group DM C0C08E97EDC
label: Kabeer openroad error tickets
---

2026-09-08 17:52 IST, group DM with Kabeer + Nakula. Kabeer: 'have assigned u 4-5 tickets related to openroad prediction errors.' Nakula: 'I haven't looked at these tickets myself. Let me know if you need any help.'

Abhishek replied 'Sure will take a look shortly' — so this is a promise made and not yet closed out. Owed: triage the tickets and come back with what they are / who fixes them.

Almost certainly the same root cause already tracked elsewhere: the OpenRoad silver chain is dead (wm-jr5bup) and OpenRoad CMOP+BEP predictions are only part-enabled (wm-xe6w4q), plus best_est_projections_at_orig has been a prod no-op since 2026-08-27 (wm-8uyfnw). Check those before treating the tickets as five separate bugs.

## Log
- 2026-09-11T14:26Z [claude-code] Sync 2026-09-11: the tickets are all closed in Linear as of 2026-09-09 — ERROR-1747 and ERROR-1778 (TurndownPredictor efp_id mapping) marked Done by Auto Mations; ERROR-1748, 1749, 1779, 1780 (openroad_auto_refi failed predictions) marked Duplicate 13:36-13:50Z. But the promise is still open: the group DM C0C08E97EDC last message is still Abhishek's 'Sure will take a look shortly' (2026-09-08 18:18 IST). What is owed is now a two-line report: all six were one root cause (dead OpenRoad silver chain → no efp_id mapping / auto_refi predictions), four were dupes and closed, two auto-resolved once silver came back.
