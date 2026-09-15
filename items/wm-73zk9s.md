---
id: wm-73zk9s
type: task
title: Review Scott's PR #6802 (DEV-1850): Nelnet payment FUND resolved at EFFDATE
status: active
priority: high
tags: [northpond, pr-review]
created: 2026-09-15T10:10:04Z
updated: 2026-09-15T16:20:09Z
source: claude-code
effort: <1h
next: Abhishek compares #6836 vs #6802, sends Scott the line-133 comment + link; close #6836 after
---

## Log
- 2026-09-15T10:10Z [claude-code] Reviewed at head 9e2e275. Prod check (2026-09-15): fix flips 34 nelnet rows edgex→balancesheet — 14 rows/$76.58 are the real bug (EFFDATE = purchase date − 1, currently failing the DQ rule), 20 rows/$811.64 are EFFDATE = purchase date (DQ rule neutral, boundary is inclusive both sides; issuance_v2 snapshot on tape day still says 'oliv'). Aug 11-14 batch resolves the same boundary to EDGEX via the earliest-investor arm, so settlement-day attribution is inconsistent. EFFDATE never blank in prod (0/2256). Alert stays red after merge: 231 FCC-leg rows (same defect, 2025 efhyf) + 680 service-fee rows. Draft comments handed to Abhishek; he posts.
- 2026-09-15T13:57Z [claude-code] Slack re-read: the day-of-transfer flip was agreed with Nate 2026-08-13 02:46 IST ('exact fund on the day of transfer'); 08-14..08-21 honoured it, 08-25+ lags by a day. Abhishek sent the purchase-day-payment question to Nate 2026-09-15 19:04 IST. Also: silver's 08-13 issuance_v2 is the first of two deliveries (no investor cols); raw 19:37 UTC re-delivery has them — needs re-parse. Notes updated (nate-and-oliv.md + meta).
- 2026-09-15T13:58Z [claude-code] Nate answered 2026-09-15 19:27 IST: purchase happens 'early in the morning', a payment on the effective date is EdgeX's. So buyer owns purchase-day cash → PR #6802 as written misbooks 20 rows/$811 to balancesheet for post-08-25 purchases. Ask Scott to read the D+1 snapshot (AS_OF_DATE <= EFFDATE + 1) or resolve off transfers, and pin with an md-test row where EFFDATE = purchase date.
- 2026-09-15T14:27Z [claude-code] Proposed fix validated on prod (temp tables, XS_DEV — DB_CREATOR has no USAGE on COMPUTE_WH_L/S): tape-first FUND (MAX_BY(pt.FUND, PURCHASE_DATE) where PURCHASE_DATE <= EFFDATE, else northpond_fund_expr at EFFDATE) changes exactly the 14 failing rows ($76.58 → balancesheet, all pass after) and keeps the 20 purchase-day rows ($811.64) in EDGEX. 0 nelnet rows fail the rule afterwards. Code handed to Abhishek to send to Scott.
- 2026-09-15T14:56Z [claude-code] Opened draft comparison PR #6836 (branch abhishek/pr6802-fund-from-purchase-tape, base = Scott's branch) with the tape-first FUND + md-test row OLV88803. Locally: unit tests pass, ruff clean, md integration test passes (101s, ephemeral CI_PR db) and fails against Scott's transform on row 3014 (balancesheet vs edgex). Worktree dp:~/claude-ws/pr6802-tape-fund/efp. Close #6836 once folded into #6802.
- 2026-09-15T16:20Z [claude-code] #6836 retargeted to master, rebased (clean), Scott's 3 commits preserved with his authorship + mine on top; lint/unit (211)/md integration all green after rebase; body rewritten as the superseding PR; marked ready for review. Scott needs to review/approve; #6802 to be closed in favour of it.
