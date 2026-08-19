---
id: wm-xmufr2
type: followup
title: Set up the 3-person call with Trishit + Nate on the EDGEX volume / Experian-vs-Oliv semantics
status: next
priority: high
size: ~15m
due: 2026-08-20
tags: [northpond, oliv, nate, edgex, trishit]
created: 2026-08-19T22:15:29Z
updated: 2026-08-19T22:15:38Z
source: claude-code
---

Committed by Abhishek to Nate on the 2026-08-20 huddle (DM D0BAD46CT27 03:22-03:33 IST, AI notes F0BRFFLN2F3, transcript F0BR7AAV15H): "I'll set up a 3 person tomorrow to address these things" — i.e. 2026-08-20. Nate agreed ("maybe tomorrow we could do like a 3-person and go over the... clarify semantics"). Abhishek's stated plan: check with Trishit first for his remaining questions, then book the slot.

WHY THE CALL EXISTS — two things the huddle surfaced but did not settle:

1. Volume. Abhishek raised the QR team's read of the issuance + positions files: ~$400-500K of loans arriving over the next 3-4 days including a ~$150K single-day jump, which QR called higher than expected given Oliv's buying was meant to start slow. (On the call Abhishek said "400K loans"; the Slack message he had just sent says $400-500K of loans, i.e. dollars.) Nate's answer was that the purchase-file composition is "really well known under a 99% BAU state" and he offered to walk it through — he did not actually explain the jump. That explanation is the main agenda item.

2. Semantics collision to resolve with Trishit present. Trishit told Abhishek that loans marked as Oliv back-book / Oliv balance sheet at our end are supposed to be Experian loans. Nate rejected that on the huddle: pre-acquisition (NorthPond) / post-acquisition (Oliv) and TransUnion / Experian are COMPLETELY INDEPENDENT events on independent timelines. Someone is working off a wrong mental model and it feeds the intended-investor / fund attribution work.

FACTS NATE GAVE ON THE CALL (usable without the meeting):
- Every purchase file for the foreseeable near term is 100% Experian. No ad-hoc one-off purchase files coming.
- There IS a backdated block of already-issued loans not scheduled to sell until ~October — those are Experian too.
- TU vs Experian is a time cutoff, not a file field: "we literally just flipped the model one day". Every application after the cutover is Experian, before is TU. The only fuzziness is a small window where an application opened on TU completed after cutover — that stays a TU loan.
- No bureau flag exists in the files today, but Nate can hand over the complete TU loan list as a STATIC set; everything else is Experian from here forward. Abhishek said he does not need it right now.
- The issuance file is the entire portfolio ever originated since inception — single database behind the whole platform, no loans exist outside it.
- Long term: Nate's plan is to keep sharing the full data payload as files, augment them as needed, and only later find a better way to expose the dataset. No integration discussion has happened yet.

Related: [[wm-unb6pr]] (v1/v2 TU vs Experian breakdown — Nate's static TU set is the unblock), [[wm-d7m3xz]] (EDGEX 2026-1NN readiness), [[wm-4sxy5d]] (EDGEX fund attribution + first live Oliv purchases).
