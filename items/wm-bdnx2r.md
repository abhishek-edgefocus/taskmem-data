---
id: wm-bdnx2r
type: correction
title: Second time in a week: finished work sat in next/active/review — Abhishek had to ask for a full re-sync
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-j523sq]
created: 2026-07-28T17:41:41Z
updated: 2026-07-28T17:41:41Z
source: claude-code
label: Second time in a week
---

This is a RECURRENCE of [[wm-y7dqmg]] (2026-07-21), not a new finding. That correction diagnosed
the exact same failure, proposed three fixes, and is still sitting in `inbox` untouched. Seven days
later the same thing happened again and the human had to prompt for it a second time — "a lot of
tasks have drifted... state has been updated, has been completed, or discarded".

## What we had vs what was actually true (2026-07-28)
- **wm-fzbz7m** — tracked `next`, urgent, due 2026-07-24 and shown as overdue in the session digest.
  Actually finished: PR #5993 merged 07-24, PR #6015 merged 07-27, DEV-1468 and DEV-1445 both Done
  in Linear, prod verified. Four days stale.
- **wm-c5jytx** — tracked `next`, urgent, due 2026-07-24, presented as the top overdue item. Its
  deliverable shipped via the two tickets above. It was also reported to the human earlier in this
  same session as the single highest-leverage thing to do today. That report was wrong.
- **wm-n7usn7** — tracked `review`. PR #6013 merged 07-24; DEV-1474 Done 07-24. Four days stale.
- **wm-unzbpr** — tracked `active` with "reply to Frank" as its next step. Abhishek had already
  replied in the 07-24 thread, and had already filed DEV-1478 for the 401 bug.
- **wm-kpyq3c** — decision record for taskmem v1, `open` since the thing was built and in daily use.
- **wm-etzegu** — `next` written into the **type** field instead of status, so a real open task was
  invisible to every next/active query for a day.
- **wm-unb6pr** — body credits PR #5884 with shipping the v1/v2 filter; #5884 was closed unmerged.

## Why it slipped — beyond what wm-y7dqmg already said
wm-y7dqmg's three causes all still hold and its fixes were never applied. Two things to add:

4. **A merged PR is the single strongest completion signal available, and nothing reads it.**
   Every one of the stale items had a `refs` entry pointing at the PR or ticket that closed it. One
   `gh pr view` per ref would have caught all four. The data to self-check was already in the item.
5. **Agents log the completion evidence and still don't set the status.** wm-fzbz7m's own log said
   "PR #5993 (DEV-1468) merged to master" on 07-24 and carried a full prod verification on 07-27,
   while the status stayed `next`. This is cause 2 from wm-y7dqmg, now with a second instance —
   writing the outcome and closing the item are being treated as separate acts, and only the first
   one happens.

## Next steps
1. Implement wm-y7dqmg's fix 1 (digest shows recently-closed items) — still not done after a week.
2. Add a reconciliation the agent runs at session start, not just on demand: for every non-terminal
   item with a `PR=` or Linear ref, fetch state and flag mismatches. Propose, never auto-close.
3. Make "set the status in the same breath as logging the outcome" an explicit line in AGENTS.md —
   the current wording ("PR merged / implementation finished -> set status=done + log") is already
   there and is being half-followed, so it needs to be a check, not a rule.

## Links
- The first occurrence, still untriaged: [[wm-y7dqmg]]
- Standing bug on the same root cause: [[wm-epb27n]]
- Project the drift concentrated in: [[wm-j523sq]]


## Environment
- taskmem: 1fbd36f
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-28T17:41:41Z
- corrected item: wm-j523sq
