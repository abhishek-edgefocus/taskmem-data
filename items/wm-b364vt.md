---
id: wm-b364vt
type: correction
title: The 55 unscored northpond loans DO have a v2 model_request — only the model_response is missing
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-zy97pd]
created: 2026-08-24T21:05:45Z
updated: 2026-08-24T21:05:45Z
source: claude-code
label: The 55 unscored northpond loans
---

VERIFIED IN PROD 2026-08-25 while building DEV-1498.

WHAT WE HAD: "55 northpond loans ... have NO bronze.api_events of any type — not
model_requests, not model_responses, not experian_request. They were never
submitted for scoring at all."

WHAT IS TRUE: all 55 DO have a northpond api_version=2 model_request. What they
lack is a model_RESPONSE. Of the funded issuance universe, 55 loans have no
model_responses row keyed on PAYLOAD:application_uuid; joining those same 55 back
to model_requests on PAYLOAD:applicationInformation.applicationUuid returns 55 of
55 — all api_version=2, all fund=northpond_balancesheet, first_seen 2026-05-13 →
2026-07-07. It matches the 634-vs-579 gap on the v2 side: 634 funded loans have a
v2 request, 579 have a v2 response.

WHY IT SLIPPED: northpond model_requests do not carry a top-level
application_uuid on either api_version — it is nested at
applicationInformation.applicationUuid. model_responses carry it flat as
application_uuid. A lookup keyed on the flat field finds nothing on the request
side and reads as "no api_events at all". Any future northpond api_events check
has to use both key positions.

WHAT IT CHANGES: the open question is no longer "were they submitted" — they
were. It is "why did the decisioning API return nothing to a request it
received", which points at the gateway/Experian failure surface ([[wm-d3qnqe]],
[[wm-u52nd6]] / DEV-1478 OAuth 401) rather than an upstream submission gap. The
May/June window still predates the 2026-07-16→21 outage ([[wm-wvdxs4]]), so that
does not explain it — but "by design, bypasses EF decisioning" is now much less
likely, because a request was made.

CONSEQUENCE FOR DEV-1498 ([[wm-79k8df]]): these 55 are exactly the loans excluded
from the new northpond slice of silver.api_credit_attributes (1,294 of 1,349
funded loans covered). The transform INNER-JOINs to model_responses because
without one there are no accepted offer terms to pin the model to, so they get no
CMOP/BEP either. They stay unscored until this is resolved.

## Environment
- taskmem: 245f802
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-24T21:05:45Z
- corrected item: wm-zy97pd
