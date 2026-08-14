---
id: wm-xe6w4q
type: task
title: Enable CMOP + BEP predictions for OpenRoad
status: next
priority: p2
size: l
people: [Abhijeet]
tags: [openroad, predictions]
links: [parent:wm-su6q4d, relates:wm-79k8df, relates:wm-prm54n, relates:wm-85nuv4, parent:wm-jr5bup]
refs: [DEV-1499=https://linear.app/edge-focus/issue/DEV-1499/setup-openroad-cmopbep]
created: 2026-07-29T15:33:45Z
updated: 2026-08-14T19:55:29Z
source: claude-code
label: OpenRoad CMOP + BEP
---

Surfaced by Abhijeet in DM 2026-07-29 19:52 IST (D0B2A3WSJ5N), while checking on the
2026-08-03 OpenRoad datastore deprecation ([[wm-prm54n]]).

- Abhijeet: "BEP pan add keles?" (did you add BEP as well?)
- Abhishek: "Nahi" (no) — then "Cmop and bep doni platforms cha baki aaje" (CMOP and BEP
  are pending for both platforms).
- Abhijeet: "northpond che pan?" (NorthPond's too?) — Abhishek: "Ho" (yes).
- Abhijeet: "acha okay".

So CMOP and BEP are confirmed outstanding on BOTH platforms. The NorthPond half already has
an item — [[wm-79k8df]], "Scope: enable CMOP + BEP predictions for NorthPond (~400-550
LOC)". This is the OpenRoad counterpart, which had none.

UNRESOLVED — whether CMOP/BEP is IN SCOPE for the 2026-08-03 deprecation milestone or
separate follow-on work. Abhijeet raised it immediately after asking "is that the only
thing left?", which reads as him checking deprecation completeness, but he did not say it
blocks 08-03 and he closed with a neutral "acha okay". Settle this before sizing — it is
the difference between a p1 sprint item and background work.

Sizing note: no OpenRoad-specific analysis has been done here. The ~400-550 LOC figure on
[[wm-79k8df]] is the NorthPond estimate for the same machinery (predictor + prep + cfframe
config + registry entry) and is carried over only as a rough analogue.

## Log
- 2026-08-03T13:44Z [claude-code] Linear ticket now exists: DEV-1499 'Setup OpenRoad CMOP/BEP' (Todo, created 2026-07-31 20:27Z). Ref added. The NorthPond counterpart got its own ticket the same evening — DEV-1498, on [[wm-79k8df]] — so the 'both platforms pending' state Abhishek described to Abhijeet on 07-29 is now formally tracked on each side.
- 2026-08-14T19:55Z [claude-code] PREREQUISITE FOUND 2026-08-15 (PROD, read-only) — this is not a greenfield build on a working
pipeline, and sizing it off the NorthPond analogue understates it.

PROD.SILVER.PREDICTED_CASHFLOWS for openroad holds ONE prediction_type, 'at_orig', 2,507 rows,
max as_of_date 2024-12-12. Nothing else. So OpenRoad predictions have not been produced for
roughly twenty months, and adding CMOP + BEP means standing up production on top of a pipeline
that is not currently producing anything at all.

That reframes the "unresolved: is CMOP/BEP in scope for the 2026-08-03 deprecation milestone"
question in the body. The deprecation retires the legacy datastores in favour of Snowflake; if
Snowflake carries no current OpenRoad predictions, the two are more entangled than "separate
follow-on work" implies. Worth settling with Abhijeet as one question rather than two.

Sequencing consequence: the silver chain has to be alive first ([[wm-85nuv4]]) — predictions are
derived downstream of positions, and silver.positions openroad stops at 2026-07-06.
