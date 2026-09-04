---
id: wm-qbrvd4
type: followup
title: Answer Scott: is the northpond transfer-lifecycle-is-well-formed validation failure a real issue?
status: next
priority: p1
size: s
due: 2026-09-05
people: [Scott]
tags: [northpond, needs-reply]
refs: [dm=https://edgefocuspartners.slack.com/archives/D0BPKHF65UK/p1788450699950239]
created: 2026-09-04T13:35:31Z
updated: 2026-09-04T13:35:31Z
source: claude-code
---

Scott DM'd on 2026-09-03 21:21 IST: northpond data has been failing a validation rule he
recently gave an id to, `transfer-lifecycle-is-well-formed`. He asked **"Is this a real
issue? asking because I want to make sure our validation rules are well calibrated."**
Abhishek replied "Thanks, will take a look!" and has not come back yet.

Very likely the same root cause as the northpond_transfers failures Kabeer and Abhijeet
chased on 2026-09-03/04 (purchase tape landing before the Nelnet positions feed —
[[wm-ytaxsk]] — and the efhyf-vs-edgex20261NN fund fallback, DEV-1711).

## Next steps
1. Confirm whether the rule is firing on the known transfer/fund-lag bug or on something else.
2. Reply to Scott in DM: real issue vs mis-calibrated rule, and which ticket covers it.
