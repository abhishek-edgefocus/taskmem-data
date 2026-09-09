---
id: wm-x3ny8b
type: followup
title: Sign off on Nakula's new Snowflake MOB Curves dashboard for NorthPond/OpenRoad
status: open
priority: p1
size: xs
due: 2026-09-10
people: [nakula]
tags: [needs-reply, slack, northpond, openroad, grafana]
links: [related:wm-e4nxre]
refs: [thread=https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5]
created: 2026-09-09T13:12:16Z
updated: 2026-09-09T13:13:23Z
source: slack #platform-data-owners
label: Nakula MOB curves signoff
---

Nakula posted a new Snowflake-backed MOB Curves dashboard on 2026-09-08 in #platform-data-owners (grafana d/cf6fae79-f881-42fa-ba5d-9074036f7581) — the Snowflake equivalent of dashboard3a-mob-curves-from-purchase, with extra breakdowns incl. JVs. On 2026-09-09 15:28 IST he followed up: 'Can I ideally get a sign-off per platform owner for this dashboard? Would want to then go for an additional review from Sean and the QRs after this.'

Abhishek owes the NorthPond (Oliv) and OpenRoad sign-off: check the panels and play with the breakdowns, confirm the data looks sane or say what is off.

Worth checking explicitly: Sean flagged on 2026-09-01 in #data-discussion that the LEGACY MOB-curves page undercounts Oliv (datastore-backed, no Nelnet support). The new page is Snowflake-backed so that gap should be gone — verifying that is most of the value of the sign-off. See wm-e4nxre.
