---
id: wm-y7dqmg
type: correction
title: Six NorthPond items sat open/next while the work was already done — Abhishek had to enumerate them manually
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-j523sq]
created: 2026-07-21T09:01:03Z
updated: 2026-07-21T09:01:03Z
source: claude-code
label: Six NorthPond items sat open/next
---

On 2026-07-21 Abhishek asked for a status sweep because he believed "a lot of them are completed" — and he was right. He then had to dictate the real status of six items one by one:

- wm-rgwdyu (Migrate Fund Monitoring, DEV-1395) — tracked `active`, actually complete.
- wm-qs96kd (Wire orphaned cashflow assets) — tracked `review`, PR merged; its OWN log already said "Backfill COMPLETE in prod and verified" on 07-20 and nothing acted on it.
- wm-3gqqxr (Review Oliv file + reply) — tracked `open`, but he had replied in Slack on 07-20 20:34 and Nate answered back at 22:44.
- wm-cunr7j (Answer Nate: which ingestions break) — tracked `open`, answered in that same 07-20 Slack reply.
- wm-u7d75w (Deprecate datastores) — tracked `review` with no owner; really waiting on Eshan after Frank's approval.
- wm-ku5sen (EDGEX warehouse) — believed materialized now; the item still asserts the 07-17 "never materialized" finding.

## Why it slipped
Three distinct causes, none of them one-off:
1. **Nothing re-checks the source of truth.** Items carrying a `slack=` ref (wm-3gqqxr, wm-cunr7j) were answered IN that thread; no agent re-read the thread, so the memory contradicted Slack for a day. Same for Linear-tracked DEV-#### items — and Linear is not even authorized in this session, so no agent could reconcile them if it tried.
2. **An item's own log can already say "COMPLETE" while its status says otherwise** (wm-qs96kd). Nothing reconciles body/log against status; a closing log line is written and the status is left behind.
3. **The SessionStart digest only shows OPEN items.** Recently-done work is invisible, so agents cannot notice "this was finished" without explicitly querying status=done or --archived. Same root cause as wm-epb27n.

## Next steps
1. Decide the cheap fix first: add a "closed in the last N days" line to the digest (see wm-epb27n), so completion is visible at all.
2. Consider a reconciliation pass agents can run on demand: for each open item with a slack/Linear ref, re-read the source and flag status mismatches — propose, never auto-close.
3. Authorize the Linear connector so DEV-#### status is reconcilable at all (16 of 31 open items are Linear-tracked).

## Links
- Project: wm-j523sq · related standing bug: wm-epb27n


## Environment
- taskmem: f6f7ddd
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-21T09:01:03Z
- corrected item: wm-j523sq
