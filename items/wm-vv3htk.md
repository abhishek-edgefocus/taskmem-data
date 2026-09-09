---
id: wm-vv3htk
type: followup
title: Review Scott's PII-hash PR #6541 for the NorthPond + OpenRoad API endpoints
status: next
priority: p1
size: s
due: 2026-09-11
people: [Scott]
tags: [northpond, openroad, needs-reply, api-health]
refs: [thread=https://edgefocuspartners.slack.com/archives/G01LRBTFG4U/p1788525464625349?thread_ts=1788375642.243529]
created: 2026-09-04T13:35:31Z
updated: 2026-09-09T13:13:23Z
source: claude-code
---

Scott merged a feature that securely hashes certain PII values and includes them in the
endpoint transaction payloads (so repeat borrowers can be detected across applications).
The Anchored API already integrates with it and is confirmed working in prod.

PR https://github.com/edgefocus/efp/pull/6541 does the same for **all other API endpoints**.
Scott posted in #team-devs (thread parent ts 1788375642.243529) asking every platform owner
to review the change for their own platform, and said explicitly:
**"I'll wait for everyone's confirmation before merging."** He sent a reminder naming
Abhishek on 2026-09-04 18:07 IST — so this is now blocking his merge.

## Next steps
1. Read PR #6541 for the northpond endpoints (`northpond_loan_fl`, `northpond_exp_loan_fl`)
   and the openroad endpoint — check which fields get hashed and that nothing the platform
   relies on downstream changes shape.
2. Reply in the #team-devs thread confirming (or flagging) for NorthPond and OpenRoad.

## Log
- 2026-09-04T19:22Z [claude-code] Reviewed PR #6541 for northpond + openroad (read the diff, the pii_hashing package and the v1/v2/openroad PII schemas at head).

VERIFIED OK: field paths in all three new pii_hash_spec.py files match the declared PII schemas exactly (northpond v1 addressZipCode, openroad addressZipcode lowercase c, northpond v2 ssn.ssn/dob.dob/name.*/currentAddress.*). Stripping behaviour is unchanged - same marker popped from the same containers; the new isinstance guards make it strictly safer (a non-dict consumerPii used to blank the whole transaction). Downstream shape is unchanged: endpoint_server_app.py pops efPiiHashes off the stripped request and puts it on the EndpointTransaction envelope, so the request column is byte-identical to before. Both northpond channels (northpond_loan_fl TU v1 and northpond_exp_loan_fl Experian v2) are served by the same class, so both are covered. CI green.

ONE BUG FOUND (northpond v2 / Experian only): dob will never hash. v2 sends MMDDYYYY (incoming_pii.py has_exact_length(8) + 'MMDDYYYY format' comment; northpond_v2_api_test.py fixture is {'dob': {'dob': '01011990'}}), but normalization.coerce_dob only accepts YYYY-MM-DD, MM/DD/YYYY and YYYYMMDD. An MMDDYYYY value matches the YYYYMMDD pattern and always fails date() because the month lands on the first two digits of the birth year (19/20). Ran the coercer directly: 01011990, 07041985, 12311999 -> None. Effect: no dob in the v2 hash block, plus a 'pii_hash uncoercible field=dob' WARNING on every Experian request. The PR's own test misses it because both v1 and v2 fixtures use harness.DOB = '1985-07-02'.

Suggested fix for Scott: accept MMDDYYYY in _DOB_PATTERNS, disambiguated from YYYYMMDD by which end holds a plausible year (a month can never be 19/20), and change the northpond v2 test fixture to a real MMDDYYYY dob.

Reply drafted for the #team-devs thread; Abhishek posts it.
- 2026-09-09T13:13Z [claude-code] Slack sweep 2026-09-09: Scott MERGED #6541 on 2026-09-04 without waiting for Abhishek. Thread record (#team-devs 1788375642.243529): Scott reminded Kabeer/Nakula/Sanjali/Kushagra/Abhishek on 09-04; Kushagra confirmed for HM, Sanjali confirmed for Foursight, Abhishek never replied. Scott then: 'Just merged this. No need to rush to deploy your APIs, but try to find a time to do so within the next week or so if appropriate.' So the ask has changed shape — it is no longer a pre-merge review gate, it is: deploy the northpond + openroad APIs carrying the PII-hash change, deadline ~2026-09-11, and say so in the thread. Reviewing the northpond_loan_fl / northpond_exp_loan_fl endpoints is still worth doing, but as pre-deploy verification, not as a merge blocker.
