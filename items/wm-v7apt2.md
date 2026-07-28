---
id: wm-v7apt2
type: followup
title: Ask Nate whether Oliv's ANL is net of recoveries or effectively gross (the 1.36 question)
status: next
priority: p1
size: xs
people: [Nate, Trishit]
tags: [northpond]
links: [parent:wm-j523sq]
refs: [DEV-1445=https://linear.app/edge-focus/issue/DEV-1445/retarget-northpond-at-orig-cashflows-to-olivs-anl]
created: 2026-07-28T17:38:16Z
updated: 2026-07-28T17:38:16Z
source: claude-code
label: Nate 1.36 ANL gross-vs-net
---

One Slack message that has been on the critical path since 2026-07-21 and never got sent. It was
step 1 of [[wm-c5jytx]] and was flagged there as "CRITICAL PATH — it biases k. Do this first; it is
one Slack message." The retarget shipped anyway on 2026-07-27, so this is now a question about
numbers already in production rather than a design gate.

## The question
Our ANL is net of our recovery assumption. Nate's ANL may have no recovery assumption at all —
`cgl / 1.36` is arithmetically consistent with 1.36 being a pure WAL divisor for a 36-month
amortising loan at 20% CPR, i.e. his "net" may actually be gross.

## Why it still matters after the ship
DEV-1445 sets `k = anl_oliv / anl_ours` per loan and re-amortises, and prod now ties out to within
1.01% of Oliv's ANL. If his number is gross and ours is net, then we have tied our curves to a
gross target and are **systematically overstating losses by roughly the recovery rate** (order of
~10% for this population) on loans EDGEX 2026-1NN is buying from 2026-07-28.

A ready-made fix exists if the answer is "gross": the northpond model_responses payload already
carries `agl` (gross) alongside `anl` (net) — `lib/efp/modeling/pl/northpond_producer.py:156-197` —
so switching the denominator is a column change, not a redesign.

## Next steps
1. Send it in the Oliv group DM (C0BJ1M304BU) — ask Nate directly whether the ANL on the issuance
   and purchase files is net of expected recoveries, or gross.
2. If gross: switch the k denominator to payload `agl` and re-run the retarget, then re-verify
   tie-out. If net: log the confirmation and close.
3. Either way tell Trishit, since he owns the model side and expected k < 1.

## Links
- Origin design item (now closed): [[wm-c5jytx]]
- Implementation that shipped without the answer: [[wm-fzbz7m]]
- Schema thread this was first raised on: [[wm-embhpy]]
- Retarget PR: https://github.com/edgefocus/efp/pull/6015
