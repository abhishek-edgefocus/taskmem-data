---
id: wm-g22j5e
type: followup
title: Get back to Trishit on the Oliv statement model: ownership + Sean's models_by_channel.json ruling
status: next
priority: p1
size: xs
due: 2026-07-30
people: [Trishit, Sean]
tags: [northpond, needs-reply]
links: [relates:wm-9s2mwd, relates:wm-j2prpv]
refs: [sean-thread=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1785264036485469]
created: 2026-07-29T13:42:21Z
updated: 2026-07-29T13:42:21Z
source: claude-code
label: Trishit Oliv statement model
---

Two live threads converge here, both from 2026-07-28/29.

SEAN'S RULING (#north-pond-tech, 2026-07-29 00:10 IST, ts 1785264036.485469, @-ing
Abhishek and Trishit): "For the Oliv statement model, I strongly suggest that we put this
in a real model object contained in `models_by_channel.json` for consistency with how we
compute predictions for every other platform. I understand a script can do the same thing
(just multiplying the predictions by a factor), but I think if we start having scripts
outside this config represent the 'true' model it becomes hard to track over time."

That "multiplying the predictions by a factor" is exactly the per-loan retarget
k = anl_oliv / anl_ours that shipped as DEV-1445 / PR #6015 ([[wm-fzbz7m]]). So Sean is
saying the retarget should not live as a transform script — it should be a registered model
object. This is a direct constraint on [[wm-9s2mwd]] (DEV-1452/QR-23) and reinforces the
predictor-class route already scoped there.

TRISHIT'S ASK (DM, 2026-07-29 18:55 IST): "for the set up of the statement model for Oliv
as pointed by Sean, are you taking that up or should I? I have some free cycles to work on
it if you are busy." Abhishek: "I read his message but I haven't looked exactly whats
required over there, let me check and get back." Trishit then said he has started an Opus
prompt to check the requirement; Abhishek: "Cool, then I will leave it to you for now. Lmk
if you need anything from my end."

SO THE OUTSTANDING REPLY IS: check what Sean's ask actually requires, then close the loop
with Trishit on ownership. Trishit is provisionally driving it, but Abhishek has not yet
looked at the requirement, so the handoff is not clean yet.

AMBIGUITY TO RESOLVE FIRST — Sean says "statement model", not "purchase tape model".
[[wm-9s2mwd]] / DEV-1452 / QR-23 are scoped to the purchase tape. Confirm with Sean or
Trishit whether these are the same thing or whether a separate statement-side model object
is intended, before scoping anything.

Existing code facts (verified on master 2026-07-28, logged on [[wm-9s2mwd]]):
models_by_channel.json already carries model_northpond, model_northpond_exp,
northpond_docker_model, northpond_loan_fl, northpond_exp_loan_fl. What is missing is the
predictor class + prep + cfframe config + registry entry in
edgefocus/modeling/predictions/run.py (northpond is in neither FORWARD_FLOW_PREDICTORS nor
TURNDOWN_PREDICTORS). ~400-550 LOC, not a config change.
