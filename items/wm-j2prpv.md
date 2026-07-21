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
updated: 2026-07-21T12:34:14Z
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
