---
id: wm-jewha5
type: task
title: Re-check Oliv test purchase files route to ignore once 2026-07-28 stubs land in S3
status: next
priority: p2
size: xs
people: [Nate]
tags: [northpond]
created: 2026-07-28T17:28:34Z
updated: 2026-07-28T17:28:44Z
source: claude-code
body: Nate said 2026-07-28 15:49 UTC he was running test purchaser files right then, and asked us to validate they are not flowing through. As of 17:27 UTC nothing new had appeared under s3://efp-raw/statements/northpond/purchase_file/ (still only the two 2026-07-24 stubs, both STATUS=ignore in prod bronze). The northpond SFTP->S3 sync had already run at 16:36 UTC and saw nothing there.

WHEN THE NEW STUBS LAND, confirm in one pass:
1. aws s3 ls s3://efp-raw/statements/northpond/purchase_file/ --recursive
2. PROD.BRONZE.STATEMENT_FILES for those keys -> expect STATUS='ignore', STATEMENT_TYPE/AS_OF_DATE/RULE_NAME NULL
3. PROD.BRONZE.STATEMENT_ROWS platform=northpond statement_type=purchase_tape -> still only the 6 x 2025 Pool events
4. PROD.SILVER.NORTHPOND_STMT_PURCHASE_TAPES -> still 372 rows / 372 loans / 6 as_of_dates

Guard being relied on: the northpond-wide ignore rule r"s3://.*/statements/northpond/.*_test\.csv", FIRST entry in NORTHPOND_RULES (find_matching_rule returns the first match). Only bites when Oliv keeps '_test' immediately before '.csv'.
---
