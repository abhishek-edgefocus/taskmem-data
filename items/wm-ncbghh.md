---
id: wm-ncbghh
type: followup
title: Answer Abhijeet in #team-devs: what should the data-freshness SLO X be before a platform going stale is a P1?
status: open
priority: p1
size: xs
due: 2026-09-10
people: [abhijeet, scott, nakula]
tags: [needs-reply, slack, data-freshness]
refs: [thread=https://edgefocuspartners.slack.com/archives/G01LRBTFG4U/p1788536318600199]
created: 2026-09-09T13:12:38Z
updated: 2026-09-09T13:12:38Z
source: slack #team-devs
label: freshness SLO threshold
---

In #team-devs on 2026-09-04 Abhijeet asked: 'For the new data pipeline, I think we should come up with some SLO. If data for a platform is stale X days, that becomes a P1. What would X be? Maybe 3 days?'

Scott then pointed the thread straight at Abhishek: '<Abhishek> is working on Improve visibility into platform data freshness which will track freshness directly (with more nuance than just is this platform's data in silver.positions/transfers/transactions). We can use this to generate P1 alerts when a platform goes stale by X (2 or 3) days.'

Nakula added a side question in the same thread — should there be a separate Y for DATASTORE staleness? Abhijeet answered that one himself: until datastores are formally demised, the end-of-week convention (Y<=7) stands.

So the open question addressed to Abhishek is the number, and it should come out of the freshness project (wm-8avh6w) rather than be guessed: different platforms have genuinely different cadences (Oliv/Nelnet daily, others D+1 or weekly), so a flat X may need to be per-platform or per-feed. That nuance is exactly what Scott says the project provides.
