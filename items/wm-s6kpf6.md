---
id: wm-s6kpf6
type: task
title: Take over NorthPond API ownership from Kabeer — discuss scope with Abhijeet Friday 2026-07-31
status: next
priority: p2
size: m
due: 2026-07-31
people: [Abhijeet, Kabeer]
tags: [northpond, oncall, ownership]
links: [parent:wm-j523sq]
refs: [dm=https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1785263143379249]
created: 2026-07-29T13:42:49Z
updated: 2026-07-31T12:56:51Z
source: claude-code
label: NorthPond API ownership handover
---

Abhijeet DM, 2026-07-28 23:45 IST - 2026-07-29 00:20 IST (D0B2A3WSJ5N).

Abhishek asked whether the realtime loan-scoring model work falls under "Everything
NorthPond" (his remit). Abhijeet: "Ho gheu shaktos" (yes you can take it) — but first ask
on #team-devs whether someone is already working on it and take over from them if so.
Then, unprompted: "API pan take over kar Kabeer kadun (pudhchya veli kahi issue vagare ala
tar tu kar fix)" — take the NorthPond API over from Kabeer too, and you fix it next time
something breaks.

Abhijeet was unsure himself whether the scoring model is Oliv-side ("oliv chya side cha
ahe ka kahi, sahebanna vichar" — ask Sean/Nate), and closed with "friday la boluya hya
baddal / sakhol charcha karu" — let's talk about this Friday, in depth.

FRIDAY 2026-07-31 IS THE ACTION. What needs settling there:
- Exact boundary of "NorthPond API" ownership passing from Kabeer to Abhishek.
- Whether the realtime v2/Experian loan-scoring model is in scope or is Oliv-side.
- Handover of anything Kabeer holds (creds, runbooks, alert routing).

ALREADY MOVING IN THAT DIRECTION — on 2026-07-29 Abhijeet assigned Abhishek three
Experian/NorthPond error tickets (ERROR-1178, ERROR-400, ERROR-1647; Abhishek: "Kar
assign"). Tracked separately.

Adjacent ownership handover in flight: the Oliv v2 model Docker container — [[wm-mmmc9t]].

## Log
- 2026-07-31T12:56Z [claude-code] HUDDLE HAPPENED 2026-07-31 17:18 IST (D0B2A3WSJ5N). Abhijeet at 17:07: 'free jhalas ki sang' (tell me when you're free); Abhishek at 17:12: '5 mins ne huddle karto'; Slackbot logged a huddle start at 17:18. This is the Friday conversation this item was created for.
CONTENT UNKNOWN — huddles leave no transcript, so whether the NorthPond API ownership boundary, the Kabeer handover, or the realtime-scoring-model scope question actually got settled cannot be read from Slack. Leaving status=next rather than assuming it closed; needs Abhishek to confirm what was agreed, or to mark done.
