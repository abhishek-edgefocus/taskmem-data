---
id: wm-buekcw
type: correction
title: Called openroad_5462736 a source gap after searching bronze on the wrong JSON path — the decisioning trail was there all along
status: inbox
tags: [taskmem-bug, correction]
created: 2026-08-25T14:37:00Z
updated: 2026-08-25T14:37:00Z
source: claude-code
label: Called openroad_5462736 a source gap
---

2026-08-25. I told Abhishek openroad_5462736 had "zero model_responses events in bronze" and was
"a real data gap, not expected", then reasoned a whole mechanism-selection answer on top of that
premise (corrections vs static reference table vs record-and-move-on). The premise was wrong.

WHAT I DID: queried `payload:offer_uuid` and a LATERAL FLATTEN of `payload:response:offers` on
`offer.value:uuid`, found nothing, and concluded the events did not exist. What I never ran was the
blunt check — `PAYLOAD::STRING ILIKE '%<uuid>%'` — which returns four events immediately.

WHAT IS ACTUALLY THERE: 2f5a0c60-7eac-48a8-8cb7-4d67fce64564 is the requestUuid, not an offer uuid.
The 2024-07-10 endpoint_transactions event carries it at request.requestUuid AND
response.requestUuid, alongside 19 APPROVED offers each with their own uuid, and there is a matching
model_requests event at the same timestamp_ns. The loan went through decisioning normally.

THIS IS THE SAME ERROR wm-zy97pd MADE, corrected in [[wm-b364vt]] four days ago: that item claimed
55 northpond loans "never hit the decisioning API" because the check keyed on a top-level
PAYLOAD:application_uuid which northpond model_requests nest under applicationInformation. Same
shape, same wrong conclusion (absence of evidence read as evidence of absence), and I had that
correction in my context when I made mine.

THE RULE: before concluding a record is absent from a variant column, search the raw payload string
for the identifier. A path-scoped query proves only that the value is not at that path. Absence at a
guessed path is not absence from the data, and "no event exists" is a claim that should always be
backed by an unscoped search first.

The real defect is in [[wm-8kx3qw]].


## Environment
- taskmem: e54fa14
- reported by: claude-code
- host: ip-10-110-205-37.ap-south-1.compute.internal
- when: 2026-08-25T14:37:00Z
