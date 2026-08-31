---
id: wm-wtqfcn
type: task
title: Reply to Sean in #data-discussion: Oliv issues 4 & 5 on the EDGEX deployment dashboard + fix timeline
status: open
created: 2026-08-31T16:46:27Z
updated: 2026-08-31T16:46:27Z
source: claude-code
---

Thread: #data-discussion (C03JR4V1448), parent ts 1787666136.977779, opened by
Sean Mills 2026-08-25 "following up on a few outstanding issues on the EDGEX
deployment dashboard".

Two tags on Abhishek, both unanswered:
- 2026-08-26 Eshan Gupta: "can you comment on the Oliv issues?" (Eshan took the
  rest of the list; Oliv items were routed to Abhishek).
- 2026-08-31 Sean Mills: "@Eshan / @Abhishek can you please advise on the
  expected timeline for the fixes you mentioned."

The Oliv items are #4 and #5, both raised by Trishit 2026-08-25:
4. Principal balance panel appears to omit the to-be-purchased loans - the gap
   is exactly the to-be-purchased quantity.
5. Oliv numbers fall and then jump back up, so something beyond #4 as well.

Related but NOT the same: wm-39q8fh (issuance_v2 / nelnet-tape stamping race)
was verified fixed in prod 2026-08-21, i.e. BEFORE these were raised - do not
answer Sean with that fix without re-checking. Kushagra's DEV-1659
(loans_in_fund reads each platform's own latest positions date) is the
candidate cause for the falling-then-recovering shape and has a PR up; he
wanted to confirm with Abhijeet who wrote the code.

Also open in the same thread: Sean says the no-breakdown view is stuck at 8/24
while per-platform views run to 8/31 - Kushagra read it as a view_as_of_date
param artifact, Sean pushed back ("Switch to breakdown = None"). That one is
Eshan's, but it lands in the same reply.
