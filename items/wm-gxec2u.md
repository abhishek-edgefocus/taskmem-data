---
id: wm-gxec2u
type: bug
title: CLI accepts any string as an item type, so 'taskmem new next "..."' silently creates type=next and the item disappears from every status view
status: inbox
tags: [taskmem-bug]
created: 2026-07-28T17:42:27Z
updated: 2026-07-28T17:42:27Z
source: claude-code
label: CLI accepts any string
---

Found while reconciling on 2026-07-28. Item wm-etzegu had `type: next` / `status: open`. An agent
clearly meant `status=next` and passed "next" as the positional `type` argument instead
(`taskmem new next "<title>"`). The CLI accepted it without complaint.

Consequence: the item was a real, actionable task (Trishit's ask for a retarget-fallback alert) but
was invisible to `find --where "status=next,active"` for a day, and showed up in no plate view. It
was only found by dumping every non-terminal file by hand.

What I expected: `new` rejects a type that is not one of the known types (task, followup, reminder,
bug, question, decision, idea, research, note, project, correction...), or at minimum warns when the
supplied type collides with a known STATUS value — "next", "open", "active", "blocked", "waiting",
"review", "inbox", "someday", "done", "dropped" are exactly the strings an agent is most likely to
put there by mistake.

Suggested fix: validate `type` in `new` against the known set and exit non-zero with the valid list.
If free-form types are deliberate, then at least reject the ten status words, since a type that is
also a status is never intentional.

Workaround used: `taskmem set wm-etzegu type=task status=next` — note `set` also accepts arbitrary
type values, so the same hole exists there.


## Environment
- taskmem: 737430a
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-28T17:42:27Z
