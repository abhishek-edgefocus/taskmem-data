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
refs: [dm=https://edgefocuspartners.slack.com/archives/C0C08E97EDC/p1788870172899589]
created: 2026-09-09T13:12:38Z
updated: 2026-09-09T13:12:38Z
source: slack group DM C0C08E97EDC
label: Kabeer openroad error tickets
---

2026-09-08 17:52 IST, group DM with Kabeer + Nakula. Kabeer: 'have assigned u 4-5 tickets related to openroad prediction errors.' Nakula: 'I haven't looked at these tickets myself. Let me know if you need any help.'

Abhishek replied 'Sure will take a look shortly' — so this is a promise made and not yet closed out. Owed: triage the tickets and come back with what they are / who fixes them.

Almost certainly the same root cause already tracked elsewhere: the OpenRoad silver chain is dead (wm-jr5bup) and OpenRoad CMOP+BEP predictions are only part-enabled (wm-xe6w4q), plus best_est_projections_at_orig has been a prod no-op since 2026-08-27 (wm-8uyfnw). Check those before treating the tickets as five separate bugs.
