---
id: wm-gxykru
type: task
title: DEV-503 int_rate_at_purchase=0: get PR #5704 reviewed + merged
status: next
priority: p2
size: s
tags: [oncall]
links: [parent:wm-3y3ckv]
refs: [DEV-503=https://linear.app/edge-focus/issue/DEV-503/int-rate-at-purchase-0-for-northpond-loans-in-positions, PR5704=https://github.com/edgefocus/efp/pull/5704]
created: 2026-07-14
updated: 2026-07-28T17:42:03Z
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
- 2026-07-28T13:19Z [claude-code] LINEAR TICKET READ 2026-07-28 (MCP reconnected). Confirms the still-needed verdict and adds four things the code/PR side did not show.

TICKET STATE: created 2025-12-10 by Chandra Shekhar, assignee Abhishek, priority Medium, due date 2025-12-31 (7 months overdue). Labels: Data Consistancy [sic], Codebase Refactor. Status is 'Todo' — it was moved BACK from In Progress to Todo on 2026-07-22T11:33Z, three weeks AFTER PR #5704 went up and while that PR was still open with green CI. Full state churn: Todo -> In Progress (2026-01-20) -> Blocked Internally (2026-01-27) -> Backlog (2026-03-31) -> In Progress (2026-06-29, auto-moved by the PR) -> Todo (2026-07-22). PR #5704 IS attached to the ticket, so whoever regressed it did so with the PR visible.

STALE BLOCKER: DEV-503 is marked blockedBy DEV-910 'Ingest Northpond data into snowflake positions'. DEV-910 was CANCELED on 2026-06-24 (assignee Nakula Neeraje, project Codebase Refactor, milestone 'All platforms using Snowflake'). So the block is dead — the relation should be removed or DEV-503 reads as blocked when it is not.

CHANDRA'S ACTUAL ANSWER (the previous session only INFERRED it from the script; the inference was right on substance but missed a step). Thread:
- Abhishek 2026-06-24: '@chandra - NorthPond Positions data in SnowFlake is now validated, do we still need to fix Datastores?'
- Chandra 2026-06-25: 'Is it a high effort from your end? if not then its better we fix there too AND UPDATE THE DATA IN NEW INDEX'
- Abhishek 2026-06-25: 'What specific dependency do we currently have on datastores?'
- Chandra 2026-06-26: 'One of the important checked in jobs is lib/efp/stats/edgex/bin/abs_datasets_job.py which uses cross platform data to create datasets we share with EDGEX investor'
=> His gate is effort, and a one-liner clears it. NEW REQUIREMENT NOT IN THE PR: 'update the data in new index' — merging the code does not retroactively fix already-generated datastore output. A regeneration/backfill of the NorthPond first-pass datastore is part of the ask and PR #5704 does not do it. Its own test plan even lists 'Verify int_rate_at_purchase is non-zero after re-generating the first-pass datastore' as an unchecked box.

UNANSWERED CLOSE REQUEST: Abhijeet Bodas, 2026-06-24, with a screenshot: 'this seems to be fixed in snowflake. Can you confirm and close this if appropriate?' Never answered. That is the literal 'is this still needed' question sitting on the ticket, and the answer is NO, do not close on those grounds — Snowflake being correct was never the issue; the datastore is the broken side and abs_datasets_job reads the datastore, not Snowflake.

PLATFORM SIDE NEVER FIXED: Eshan 2026-01-12 posted Nate's reply — NorthPond confirmed OriginalInterestRate=0 is an ACTIVE issue on their end, and said to use CurrentInterestRate meanwhile. Two options were put up: (a) reference CurrentInterestRate in standposFirstPass, (b) push NorthPond to fix it upstream. (a) is what PR #5704 does; (b) never happened. Eshan's position was 'I dont think it is impacting us anywhere... its just a matter of sanity of our datastores' — Chandra rebutted the same day: 'I require it to share northpond static data with PT for edgex deals. I will then make that adjustment for now', i.e. he has been hand-adjusting since January. That manual adjustment plus the conditions.py:43 northpond carve-out (PR #4425, 2026-01-19) are the two live workarounds the merge should retire.

SO THE FULL CLOSE-OUT IS FOUR STEPS, not one: (1) get #5704 reviewed and merged; (2) regenerate/backfill the NorthPond first-pass datastore so existing data is corrected — Chandra's 'new index'; (3) revert the conditions.py:43 northpond carve-out; (4) answer Abhijeet on the ticket, drop the dead DEV-910 blocker, move status off Todo.
- 2026-07-28T13:33Z [claude-code] DEPRECATION PREMISE CHECKED 2026-07-28 — Abhishek asked 'but we deprecated datastores, right?'. Answer: yes for northpond, but it does NOT make DEV-503 moot. Verdict unchanged: still needed.

WHAT WAS ACTUALLY DEPRECATED: PR #5936 (DEV-1450, merged 2026-07-21, see [[wm-u7d75w]]) added ('DatastorePositions','northpond') and ('DatastoreTransactions','northpond') to DEPRECATION_REGISTRY with snowflake_routable=True. Registry-based, additive, nothing deleted. It emits a warning and ENABLES an opt-in source='snowflake' path — it does not reroute anything by itself.

WHY THE EDGEX PATH IS UNAFFECTED — three independent reasons, all verified on origin/master today:
1. source defaults to 'datastore' (base_datastore.py:175/221/1400/1430). Routing is opt-in per call.
2. NOBODY IN THE REPO PASSES source='snowflake'. git grep across lib/ bin/ edgefocus/ orchestration/ returns only the definitions and error strings themselves — zero production callers. The routing exists and is unused.
3. datastore_positions.py:87 _load_from_snowflake raises NotImplementedError unless exactly ONE platform. abs_data_requests.load_datasets() calls DatastorePositions(platforms=constants.PLATFORMS, interval='latest', index=self.index).data() — all 7 platforms in one call (constants.PLATFORMS = lc, upgrade, marlette, prosper, sofi, happymoney, northpond). So it STRUCTURALLY cannot route, regardless of registry state. Same for the second call at abs_data_requests.py:659.
Net: the EDGEX ABS job still reads the legacy datastore, so int_rate_at_purchase is still 0 for northpond there. The Snowflake comparison data agrees — 98.74%% mismatch through 2026-07-19, i.e. after the deprecation merged.

THE REAL MIGRATION IS DEV-1457, AND IT HAS NOT STARTED: 'EDGEX investor data share: Snowflake equivalents for the datastores we read'. Created 2026-07-17 by Chandra Shekhar, assignee Eshan Gupta, priority HIGH, status BACKLOG, never started. It documents that EDGEX produces 5 investor datasets monthly from bin/abs_datasets_job.py reading 16 DATASTORES across all 7 platforms, and that the June 2026 run already emitted a past-deadline deprecation warning for marlette positions. It names both blockers I found independently: (1) source='snowflake' is one-platform-at-a-time vs EDGEX's all-7 call; (2) NO CFFRAME DATASTORE HAS A SNOWFLAKE PATH AT ALL — DatastoreCfframeFromPurch, DatastoreCfframe, DatastoreCalendarMonthCfframe, DatastorePredCfframeFromPurch, DatastoreSimPredCfframeFromPurch (the last pinned at index 1160 so historical EF grades never move). Every curve in the deliverable comes from a cfframe. Only DatastorePositions/DatastoreTransactions are registered; DatastoreTransfers and the 7 Statement* datastores have no registry entry either.
Its row #1 literally called out DEV-503's table: 'Routable today for sofi/prosper/marlette/happymoney/upgrade — but NOT lc or northpond. What is the plan for those two?' — written 2026-07-17, four days before #5936 closed the northpond half. lc is STILL not routable, which alone keeps the multi-platform call on legacy.

STRONGEST ARGUMENT THE LEGACY FIX MUST LAND ANYWAY: DEV-1457's own closing question — 'if positions come from silver and cfframes from the legacy datastore, could they disagree about the loan universe?' Since cfframes have no Snowflake path and none is planned, the likely answer is that EDGEX keeps reading positions from LEGACY for consistency with the cfframes. That is a long-lived legacy read, not a soon-to-die one, so the legacy datastore has to be CORRECT — deprecation does not excuse it.

FOLLOW-UP WORTH FILING (not filed): DEV-1457 is High priority, unstarted since 2026-07-17, assigned to Eshan, and is the umbrella that eventually retires this whole class of problem. No taskmem item exists for it.
- 2026-07-28T13:40Z [claude-code] 2026-07-28: Abhishek raised that the new Oliv file ingestion will break the old pipeline. He is right — filed [[wm-tvjjgw]]. Relevant to this item because the legacy purchase-tape feed (efp-derived xlsx via mirror_trade_files northpond_ff) is due to stop in favour of the DEV-1474 csv, and legacy statement_loan_positions/transactions depend on it for fund classification. If legacy northpond is left to starve, #5704 fixes a rate on a table that is going stale anyway; if legacy is kept alive to serve EDGEX until DEV-1457 lands, #5704 plus a purchase-tape repoint are both required. Either way the two decisions should be taken together, not separately.
- 2026-07-28T17:39Z [claude-code] RECONCILED 2026-07-28 (GitHub + Linear) — no change in verdict, still needed, but pinning the live state: PR #5704 is OPEN and STILL A DRAFT (isDraft=true), REVIEW_REQUIRED, untouched since 2026-07-01, mergeable. Linear DEV-503 is still Todo (regressed there 2026-07-22T11:33Z) with due date 2025-12-31, i.e. seven months overdue. So the 'ask for review' action recorded here cannot actually be taken until the PR comes out of draft — that is the first step, not the review request.
