---
id: wm-gxykru
type: task
title: DEV-503 int_rate_at_purchase=0: get PR #5704 reviewed + merged
status: review
priority: p2
size: s
tags: [oncall]
links: [parent:wm-3y3ckv]
refs: [DEV-503=https://linear.app/edge-focus/issue/DEV-503/int-rate-at-purchase-0-for-northpond-loans-in-positions, PR5704=https://github.com/edgefocus/efp/pull/5704]
created: 2026-07-14
updated: 2026-07-28T12:58:28Z
source: dpx-tasks #9
label: NorthPond int_rate root-cause
---

## Log
- 2026-07-15T14:44Z [importer] imported from dpx ~/tasks #9
- 2026-07-16T13:17Z [claude-code] active -> next (2026-07-16): Abhishek confirms this is real work he intends to do, but not now — no capacity. Not blocked on anything external, so 'waiting' would be wrong; it is queued, not in progress. Title also dropped a stale '(in progress)' suffix carried over from the dpx ~/tasks import; nobody has actually started it (no investigation logged since import 2026-07-15).
- 2026-07-28T12:58Z [claude-code] SESSION FOUND + STILL-NEEDED CHECK 2026-07-28.

THE CLAUDE SESSION: dpx ~/.claude/projects/-home-abhishek/eee8da40-f451-42e9-96bd-5973851f6034.jsonl (2026-06-29 -> 2026-07-01, 43 DEV-503 hits). It did NOT just root-cause — it shipped the fix. Six turns: infer Chandra Shekhar's answer from the script he named -> 'does it make sense to fix datastores given SF is in place' -> what is he implying about abs_datasets_job.py -> is it a one-liner -> take latest master, implement, open PR -> tests failed (transient CI, re-run triggered). Session ended there; nothing since.

ROOT CAUSE (settled, no further investigation needed): NorthPond's raw tapes leave OriginalInterestRate=0 for experimental-fund loans. NorthPond confirmed CurrentInterestRate equals the original rate because they never re-rate after origination. Legacy datastore DatastoreStandPosFirstPassNorthpond._build_df() maps OriginalInterestRate -> int_rate_at_purchase, so it lands 0. Silver was never affected: transfers.py:193 has COALESCE(NULLIF(p.ORIGINALINTERESTRATE,0), p.CURRENTINTERESTRATE)/100.0 and positions.py:206 guards again with COALESCE(NULLIF(pur.INT_RATE,0), i.INTEREST_RATE/100.0). Pre-existing fix commit 855ca43d8 on abandoned branch origin/DEV-503.

WHY IT IS NOT DEAD LEGACY CODE (this was the crux, and Chandra Shekhar's point): abs_data_requests.py:24,95 still builds positions_df from DatastorePositions, NOT silver. That feeds lib/efp/stats/edgex/bin/abs_datasets_job.py, the investor-facing EDGEX ABS deliverable, which uses int_rate_at_purchase at lines 829/841/854 and renames it to Original_Interest_Rate / Original_Loan_Interest_Rate in the tape. Verified still true on origin/master today. SF being correct does not help because this job bypasses Snowflake.

STILL NEEDED: YES. Evidence:
- PR #5704 (branch abhishek/dev-503-northpond-int-rate-at-purchase) is OPEN and unmerged since 2026-06-29, last touched 2026-07-01. mergeable=MERGEABLE, mergeStateStatus=BLOCKED — i.e. only missing an approving review, not a rebase. CI green (Run Tests SUCCESS, Seer Code Review SUCCESS). Zero human comments; the only comment is the linear-code linkback bot.
- origin/master still has OriginalInterestRate at datastore_stand_pos_first_pass_northpond.py lines 46/51. File untouched since the 2024 ruff-format commit f2c50aed7, so no conflict risk.
- Live data: DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY, platform=northpond, INT_RATE_AT_PURCHASE mismatch is a flat 98.74% (706/715) on every comparable date through the latest 2026-07-19, while INT_RATE and INSTALLMENT are both 0.00% mismatch. Exactly the DEV-503 signature: datastore 0, silver correct.

WORKAROUND ALREADY IN PROD (found today, not in the ticket): conditions.py:43 int_rate_condition reads (df['int_rate_at_purchase'] > 0.0) | (df['platform'] == 'northpond'). Added 2026-01-19 in PR #4425 'Edgex: adding northpond and happymoney to data request'. So NorthPond loans are no longer DROPPED from the datasets — that half of the reported impact is already masked. The remaining live impact is that they go out to EDGEX with Original_Interest_Rate = 0.0. That carve-out should be reverted as part of merging #5704, otherwise a future genuine zero-rate NorthPond loan sails through silently.

ACTION: this is not research work any more, it is a one-line PR needing a reviewer. Ask for review on #5704 (+ revert the conditions.py carve-out). Root-causing is DONE — retitle/re-scope accordingly.

Linear ticket state itself not checked: both Linear MCP servers are unauthenticated in this session.
