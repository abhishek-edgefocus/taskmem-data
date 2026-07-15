---
id: wm-j9jxpc
type: task
title: Check missing statement files for NorthPond and confirm in Kushagra's thread (before Friday dev call)
status: next
size: s
due: 2026-07-17
people: [Kushagra]
tags: [northpond, needs-reply]
links: [relates:wm-3tdn24, relates:wm-qu4cr7]
refs: [slack=https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1784107733166829?thread_ts=1784107733.166829&cid=C0B6M0AQKB5]
created: 2026-07-15T14:56:55Z
updated: 2026-07-15T19:36:19Z
source: intake-review
---

Kushagra asked in #platform-data-owners (2026-07-15 14:58 IST) for each
platform owner to confirm in-thread once they've checked the missing
statement files for their platform — needed before the Friday dev call
(2026-07-17) so the list can be handed to ops. Status in-thread: Nakula
confirmed for Innovate (file missing, impact being assessed), Sanjali for
Prosper (missing but ignorable — old 2023 file, went into the
acknowledgment sheet), Abhijeet says he addressed all 5 of his and is
checking why the list hasn't refreshed. NorthPond (mine) is the one still
unconfirmed. Process per Kushagra: decide per file whether it affects the
platform or can be ignored; if it affects, start the conversation with the
platform cc'ing ops; either way record it in the acknowledgment sheet.

No blocker on Kushagra: the missing-files list IS in the thread — the
parent message's screenshot (F0BJACCTJU8) of the "Missing Platform Data"
dashboard. NorthPond row: statement_type=positions (NorthPond daily loan
tape), expected daily, 3 missing dates: 2024-08-09, 2024-08-28, and a
third truncated in the screenshot ("2024-0…" — read it off the dashboard).
Last checked 2026-07-12. All are old 2024 files, so likely the
Sanjali/Prosper pattern (ignorable → acknowledgment sheet), but verify.

## Next steps
1. Get the third missing date from the "Missing Platform Data" dashboard
   (screenshot truncates it).
2. For each of the 3 missing positions files: check whether it affects the
   platform or can be ignored. First rule out overlap with the
   already-closed missing-window alerts (ERROR-1524, wm-3tdn24) so nothing
   is double-reported.
3. Record the per-file outcome in the acknowledgment sheet (link not yet
   known — Sanjali used it on 2026-07-15, ask her or Kushagra if not
   findable).
4. Reply in Kushagra's thread confirming — before the Friday dev call.

## Links
- Source thread (Kushagra's ask): https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1784107733166829?thread_ts=1784107733.166829&cid=C0B6M0AQKB5
- Possibly-overlapping closed work: wm-3tdn24 / ERROR-1524 — https://linear.app/edge-focus/issue/ERROR-1524/missing-statement-filenorthpondpositionsnorthpond-loan-positions-4
- Related open investigation: wm-qu4cr7 / ERROR-1231 — https://linear.app/edge-focus/issue/ERROR-1231/northpond-issued-missing-gateway-responses-15-issued-northpond-loans

## Log
- 2026-07-15T14:56Z [intake-review] captured from Slack mention sweep (intake demo run); dedup anchor is the message permalink in refs
- 2026-07-15T15:08Z [intake-review] intake re-check: Kushagra's thread still has no NorthPond confirmation from Abhishek as of this evening; Nakula/Sanjali confirmed, Abhijeet checking his refresh
- 2026-07-15T15:12Z [intake-review] upgraded to pickup-ready standard (context, next steps, links)
- 2026-07-15T15:16Z [claude-code] Planned for tonight: unblock only — find/ask for the missing-files list in-thread; per-file analysis tomorrow
- 2026-07-15T15:23Z [claude-code] Corrected: no blocker on Kushagra — list is the dashboard screenshot in the thread parent (F0BJACCTJU8). NorthPond = 3 missing daily positions files (2024-08-09, 2024-08-28, +1 truncated). Rewrote next steps accordingly.
- 2026-07-15T19:36Z [claude-code] tagged needs-reply: Kushagra's @-mention in #platform-data-owners is still unanswered; Nakula/Sanjali/Abhijeet have replied
