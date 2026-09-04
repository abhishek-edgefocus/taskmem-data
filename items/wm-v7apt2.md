---
id: wm-v7apt2
type: followup
title: Ask Nate whether Oliv's ANL is net of recoveries or effectively gross (the 1.36 question)
status: next
priority: p1
size: xs
people: [Nate, Trishit]
tags: [northpond]
links: [follows:wm-c5jytx, relates:wm-vye9hn, relates:wm-btu784, parent:wm-btu784]
refs: [DEV-1445=https://linear.app/edge-focus/issue/DEV-1445/retarget-northpond-at-orig-cashflows-to-olivs-anl]
created: 2026-07-28T17:38:16Z
updated: 2026-09-04T13:35:53Z
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

## Log
- 2026-07-28T17:38Z [claude-code] Created 2026-07-28 during a full reconciliation. Confirmed still unasked by Slack search over the Oliv group DM: no message from or to Nate mentions net-of-recoveries, gross, or 1.36. Carried out of [[wm-c5jytx]] at close so it does not die with that item.
- 2026-08-22T09:57Z [claude-code] 2026-08-22 [claude-code, from the DEV-1446 dashboard build]: prod evidence that narrows the question, though it does not close it — only Nate can do that.

On edgex20261NN, 265 loans carry both models (silver.positions.ANL joined to silver.northpond_stmt_issuance_v2 on APPLICATION_ID = APPLICATION_UUID):
- Oliv CGL / Oliv ANL = 1.36, and it is 1.36 to two decimals on EVERY loan and every intended_investor bucket (415 edgex-intended, 146 oliv-intended). That is not a modelled recovery rate, it is a constant multiplier.
- Our own gold.predicted_cashflows_mob lifetime CGL / CNL for the same fund = 1.10.
- Our ANL (11.06% WA) sits almost exactly on our lifetime CNL (11.62%), not on anything annualised.

Reading: if our "ANL" is numerically a cumulative net loss, and Oliv's ANL sits within 10bps of ours, then Oliv's ANL is most likely cumulative too — and the 1.36 is their gross-to-net assumption, not an annualisation. That would make the CGL gap (EF 12.77% vs Oliv 14.91%, -213bps) the real disagreement: recoveries, not loss level.

Still needs Nate to confirm. The question to ask him is now sharper: "is the 1.36 your recovery assumption (CGL to CNL), or is it a WAL-based annualisation?"
- 2026-09-04T13:35Z [claude-code] 2026-09-04 Slack sweep: confirmed still UNSENT. The Oliv group DM (C0BJ1M304BU) has had no message since Nate's 2026-08-08 update; the ANL/1.36 question was never posted.
