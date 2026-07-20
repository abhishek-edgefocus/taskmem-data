---
id: wm-epb27n
type: bug
title: Agents miss existing items and re-do or re-ask about work already handled
status: inbox
tags: [taskmem-bug]
created: 2026-07-20T15:58:31Z
updated: 2026-07-20T15:58:31Z
source: claude-code
label: Agents miss existing items
---

Abhishek repeatedly has to tell agents that something was already handled or
already exists — the agent didn't find it in the memory before acting. Seen
across sessions and reproduced in the agent evals (round 2 s9: the dedup trap;
"search before you create" is in AGENTS.md but loses to eagerness).

Expected: an agent orients on the memory and notices the existing/handled item
without being prompted.
Actual: it creates a near-duplicate, re-asks a settled question, or reports
work as outstanding when an item already records it as done.

Possible directions (not yet chosen):
- the SessionStart digest shows only open items, so recently-DONE work is
  invisible unless the agent explicitly queries --archived / status=done;
  a "closed in the last N days" line might remove most of these misses.
- search-before-create is a prose rule with no mechanism behind it.


## Environment
- taskmem: 9ded1a9
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-20T15:58:31Z
