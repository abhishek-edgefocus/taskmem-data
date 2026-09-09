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
links: [related:wm-8avh6w]
refs: [thread=https://edgefocuspartners.slack.com/archives/G01LRBTFG4U/p1788536318600199]
created: 2026-09-09T13:12:38Z
updated: 2026-09-09T15:24:23Z
source: slack #team-devs
label: freshness SLO threshold
---

In #team-devs on 2026-09-04 Abhijeet asked: 'For the new data pipeline, I think we should come up with some SLO. If data for a platform is stale X days, that becomes a P1. What would X be? Maybe 3 days?'

Scott then pointed the thread straight at Abhishek: '<Abhishek> is working on Improve visibility into platform data freshness which will track freshness directly (with more nuance than just is this platform's data in silver.positions/transfers/transactions). We can use this to generate P1 alerts when a platform goes stale by X (2 or 3) days.'

Nakula added a side question in the same thread — should there be a separate Y for DATASTORE staleness? Abhijeet answered that one himself: until datastores are formally demised, the end-of-week convention (Y<=7) stands.

So the open question addressed to Abhishek is the number, and it should come out of the freshness project (wm-8avh6w) rather than be guessed: different platforms have genuinely different cadences (Oliv/Nelnet daily, others D+1 or weekly), so a flat X may need to be per-platform or per-feed. That nuance is exactly what Scott says the project provides.

## Log
- 2026-09-09T15:24Z [claude-code] Draft answer prepared 2026-09-09, in ~/data-freshness-next-actions.md section 1. The answer is that X is not one number, it is five, and they already exist in Scott's expectations.py pinned by a test: daily late 0 / P1 1, weekly 9/16, irregular 10/16, tape 15/24, monthly 32/40. Proposed rule: P1 = a series past its band's OVERDUE threshold, not its late threshold. For Abhijeet's actual worry (a daily platform going quiet) that makes X=1 day, not 3 — three days of a missing daily feed is three purchase cycles and is a backfill, not a P1. Exception: the API gateway cannot ride the day bands, because gateway_last_order.py already uses per-channel thresholds from 8 minutes to 16 hours (120x spread), so gateway staleness stays in hours per channel. Nakula's datastore Y<=7 needs nothing from this project — Abhijeet already answered it himself. Worth noting in the thread if he pushes: the bands are Scott's, not mine; the architecture doc argues for keeping them over the per-series tuning I originally proposed, and that reversal is the strongest argument for them. Not sent — needs Abhishek to post.
