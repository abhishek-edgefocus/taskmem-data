---
id: wm-j2prpv
type: task
title: Force the QR-23 decision with Trishit: arithmetic curve derivation vs model-run CFFrame
status: next
priority: p0
size: s
due: 2026-07-21
tags: [northpond]
links: [relates:wm-c5jytx, relates:wm-9s2mwd, parent:wm-j523sq]
created: 2026-07-21T12:22:52Z
updated: 2026-07-21T17:38:01Z
source: claude-code
---

Gates the scope of [[wm-c5jytx]] (due 2026-07-24) and all of [[wm-9s2mwd]] / [[wm-79k8df]].

Two incompatible methods are on record and nobody has reconciled them:
- THE CALL (2026-07-16, Trishit + Abhishek + Abhijeet + Nakula + Nate): derive monthly loss curves ARITHMETICALLY — one static unit curve shape identical for every loan, rescaled by each loan's terminal CGL; prepay flat 20% for life; ratios hardcoded. Nakula: 'pretty much the only input we need is the CGL number', Trishit: 'Exactly. Yes.'
- SEAN'S QR-23 + DEV-1452 (filed 2026-07-17, the DAY AFTER that call, and Sean was NOT on it): run our existing API model with Oliv's ANL as a stress factor to produce a full self-consistent CFFrame.

Why it must be settled before any build: the arithmetic route needs no predictor class and no conda prediction path; Sean's route needs a whole NorthPond predictor + prep + cfframe config (~400-550 LOC, same machinery as wm-79k8df). Order-of-magnitude difference in scope against a 2026-07-24 commitment.

Only Sean's route yields CMOP/BEP — the call confirmed Oliv's model cannot (Nakula: 'using their model we cant generate BPS or COP'; Trishit: 'Exactly.').

Trishit is the right decider: he owns QR-23, was on the call, and told the Sean/Nakula/Abhishek group DM on 2026-07-17 21:47 IST that he would 'take an initial look today and update the group on what is the best way forward'. No update in the 4 days since; that DM (C0BJ54B95Q9) has had zero messages after it.

Also raise: the 1.82 / 1.36 scalars Oliv uses to reach CGL and ANL were themselves fitted off a curve SEAN sent NorthPond, so stressing our model by their ANL partly re-imports our own curve assumption. Nobody on the call could recall which curve it was or why — investigating it is already an open action on Trishit.

## Log
- 2026-07-21T12:39Z [claude-code] STATUS CHECK 2026-07-21 (Abhishek's confirmed-vs-pending review). Re-read the Sean/Trishit/Nakula/Abhishek group DM C0BJ54B95Q9: STILL zero messages after Trishit's 2026-07-17 21:47 IST 'I'll take an initial look today and update the group on what's the best way forward'. Confirmed via a from:<@U02PQS54UJD> after:2026-07-16 search — Sean has posted plenty elsewhere since, nothing further here. Four days of silence on the one decision that sizes the 2026-07-24 build.

This remains the ONLY genuinely scope-changing open item in the whole Oliv/EDGEX picture: everything else pending is either an overdue deliverable from Nate (final schema, purchase-tape schema — wm-embhpy) or a question nobody has asked yet (backfill). Arithmetic route = CGL x hardcoded ratio vector, no predictor class. Sean's route = NorthPond predictor + prep + cfframe config, ~400-550 LOC. Escalate today.
- 2026-07-21T17:38Z [claude-code] DECIDED 2026-07-21 — Abhishek + Trishit, verbally. The arithmetic-vs-model-run fork is RESOLVED in favour of Sean's route (QR-23 / DEV-1452), implemented as a LINEAR RETARGET rather than a re-fit:

METHOD: take OUR model's origination prediction, divide by OUR ANL, multiply by NATE'S ANL from the issuance file, AT LOAN LEVEL. k = anl_oliv / anl_ours applied per loan. The rescaled predictions become the canonical at_orig predictions, flow downstream, and CFFrames are derived from them — i.e. everything consumes the retargeted numbers, not the raw API-model numbers.

This is Sean's 'Oliv ANL as a stress factor, explicitly NOT as a GBM feature' realised as a ratio scale. It supersedes the 2026-07-16 call's arithmetic curve derivation (static unit curve x terminal CGL). The arithmetic route is DEAD — do not build it.

CONSEQUENCE: we DO need the northpond forward-flow predictor path after all (wm-9s2mwd / wm-79k8df machinery, ~400-550 LOC estimate), since the thing being scaled is our model's OP curve. Also means Abhijeet's original framing (store OPs as prediction_type='at_orig' in silver.predicted_cashflows) is satisfiable again — the curves are ours, retargeted by their ANL.

NOTE FOR WHOEVER BUILDS IT: this is our model retargeted to their loss LEVEL, carrying our timing/shape/prepay/recovery assumptions. It is NOT 'their model's predictions' and should not be described that way to Sean or investors. Open design questions logged on wm-c5jytx.
