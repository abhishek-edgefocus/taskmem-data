---
id: wm-jewha5
type: task
title: Re-check Oliv test purchase files route to ignore once 2026-07-28 stubs land in S3
status: waiting
priority: p2
size: xs
waiting_on: Nate
nudge: 2026-07-30
people: [Nate]
tags: [northpond]
links: [relates:wm-n7usn7]
created: 2026-07-28T17:28:34Z
updated: 2026-07-31T12:56:14Z
source: claude-code
---

Nate said 2026-07-28 15:49 UTC he was running test purchaser files right then, and
asked us to validate they are not flowing through. As of 17:27 UTC nothing new had
appeared under `s3://efp-raw/statements/northpond/purchase_file/` (still only the two
2026-07-24 stubs, both STATUS=ignore in prod bronze). The northpond SFTP->S3 sync had
already run at 16:36 UTC and saw nothing there.

WHEN THE NEW STUBS LAND, confirm in one pass:

1. `aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive`
2. PROD.BRONZE.STATEMENT_FILES for those keys -> expect STATUS='ignore', STATEMENT_TYPE/AS_OF_DATE/RULE_NAME NULL
3. PROD.BRONZE.STATEMENT_ROWS platform=northpond statement_type=purchase_tape -> still only the 6 x 2025 Pool events
4. PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES -> still 372 rows / 372 loans / 6 as_of_dates

Guard being relied on: the northpond-wide ignore rule
`r"s3://.*/statements/northpond/.*_test\.csv"`, FIRST entry in NORTHPOND_RULES
(find_matching_rule returns the first match). Only bites when Oliv keeps `_test`
immediately before `.csv`.

Verification already done on 2026-07-24 stubs + the full routing matrix is logged on
[[wm-n7usn7]] (2026-07-28 entry).

## Log
- 2026-07-28T17:40Z [claude-code] next -> waiting 2026-07-28: the next movement is Nate's, not ours. He said at 15:49 UTC (21:19 IST) he was running the test purchaser files 'at this moment' and asked us to validate they are not flowing through, but as of 17:27 UTC nothing new had landed under s3://efp-raw/statements/northpond/purchase_file/. Nothing to check until his files appear, so waiting on Nate with a nudge tomorrow rather than sitting in next as if it were actionable.
- 2026-07-29T13:41Z [claude-code] 2026-07-29T13:45Z RE-CHECK (~20h after Nate's 'running test purchaser files' message): NOTHING NEW LANDED, PROD STILL CLEAN.

S3: s3://efp-raw/statements/northpond/purchase_file/ still holds ONLY the two 2026-07-24 objects (purchase_file_v0_20260723_test.csv 1033 B, purchase_file_v1_20260723_test.csv 731 B). A full scan of the whole northpond prefix for 'purchase' and for 'test|latest' returns nothing else new — no 20260728/20260729 stubs at all. So whatever Nate ran on their side never reached Oliv's SFTP, hence never reached our mirror.

PROD UNCHANGED: bronze.statement_files — both stubs still STATUS=ignore (statement_type/as_of_date/rule_name NULL); purchase_file_legacy_20260723.csv still STATUS=unknown. bronze.statement_rows northpond/purchase_tape — only the 6 x 2025 Pool events (72/111/73/60/59/75), zero 2026. silver.northpond_stmt_purchase_tapes — 372 rows / 372 loans / same 6 as_of_dates. Byte-for-byte the same as the 2026-07-28 check.

PIPELINE IS ALIVE (so absence is real, not a stalled sensor): northpond registered 6 files on 2026-07-28 across three runs (05:43, 09:41, 11:42 PT). The 2026-07-29 loan tape + transaction tape landed in S3 at 13:38 UTC (06:38 PT) and were not yet registered at 13:40 UTC — that is the normal ~5 min lag, not a stall. Other platforms (lc, upgrade, prosper, anchored, openroad, sofi) all registered on 2026-07-29. The mirror demonstrably covers purchase_file/ since the 07-24 stubs arrived through it.

SLACK: no further message from Nate in C0BJ1M304BU since 2026-07-28 21:19 IST.

CONCLUSION: nothing to catch. The guard was never exercised by yesterday's run because no file arrived. Item stays waiting on Nate — either his test drop did not go to SFTP, or it goes to a path/environment we do not mirror. Worth asking him which, since 'we ran test files' with zero S3 arrival is itself information about their delivery path.
- 2026-07-29T13:44Z [claude-code] NUDGE FIRED 2026-07-29, still waiting. Re-read the full C0BJ1M304BU thread (parent ts 1785253752.403349): Nate posted at 21:19:12 IST 'we're running some of those test purchaser files at this moment' and at 21:19:28 'just calling out so you can validate they're not accidentally flowing through the system in any way'. There has been NO further message from him in that thread or that group DM since — the last message in the channel is still his 21:19 heads-up. So no new signal that the stubs landed; the S3/bronze checks in the body have not been re-run in this sweep.
Leaving status=waiting rather than flipping to next, because the trigger condition (new files under s3://efp-raw/statements/northpond/purchase_file/) is still unverified. Two ways to close it: run check 1 in the body directly, or ask Nate whether the test run actually produced files.
- 2026-07-31T12:56Z [claude-code] STILL WAITING, AND NOW WITH A REASON (2026-07-31). The trigger for this check was Nate's 07-28 test purchase files. Two days on, no purchase activity of ANY kind has appeared — a parallel session verified this on 07-30 ([[wm-n7usn7]]), and the business reason is now known: Trishit 2026-07-30 23:08 IST said Oliv is 'sort of already building a backbook but nothing so far on direct edgex bookings', with Dustin reporting a delay in account creation; Abhishek added that per Frank some platforms are deliberately waiting until Monday for next month's warehouse triggers.
So this is not Nate being slow — the files genuinely are not coming yet. The ignore-rule guard remains unexercised against real traffic. Practical read: fold this check into the first real purchase-file landing (expected Monday 2026-08-03) rather than nudging Nate again. Nudge moved accordingly.
