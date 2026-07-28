---
id: wm-5z3pjt
type: task
title: Map EDGEX 2026-1NN Oliv investor IDs (INV105 / INV103) into the northpond fund mapping
status: next
priority: p1
size: m
people: [Dustin, Abhijeet]
tags: [northpond, edgex]
links: [parent:wm-j523sq]
created: 2026-07-28T11:01:04Z
updated: 2026-07-28T17:40:04Z
source: claude-code
---

Abhijeet asked in #platform-data-owners (2026-07-28 16:26 IST) that each platform owner complete the EDGEX 2026-1NN investor-ID mapping; Dustin marked the ID list complete 2026-07-28 04:31 IST. Oliv/NorthPond IDs: EDGEX Purchaser I = `INV105`, EDGEX Grantor Trust = `INV103`.

Current state (verified on ~/repos/efp master, 2026-07-28): NorthPond has NO investor-ID concept at all. `edgefocus/transformations/silver/statement_rows/northpond/constants.py` maps fund by SFTP ACCOUNT_NAME only — `NORTHPOND_ACCOUNT_FUND_MAP = {ef_northpond: experimental, northpond_efhyf: efhyf}`. No EDGEX account exists in `configs/default_passwords.json` for northpond, and INV105/INV103 appear nowhere in the repo. The purchase-tape schema (`stmt_purchase_tapes.py`) has no investor/account column either; FUND is derived by the purchase-tape membership IFF in `FUND_WITH_PURCHASE_TAPE_EXPR`.

Open question to resolve first: how will EDGEX-purchased Oliv loans be distinguished — a new SFTP account/sftp_key (e.g. `northpond_edgex*`) like the efhyf one, or a new investor_id field on the Oliv tape? Ask Dustin/Nate.

Cross-platform gaps worth flagging, not ours to fix (shared code):
- Grantor Trust IDs are unmapped for EVERY platform (Upgrade 9417954, Prosper 15983181, Oliv INV103 all absent from the fund maps); there is no grantor-trust FUNDS constant.
- `stmt_utils.resolve_edgex_purchaser_fund` has no 2026-1NN cutoff: EDGEX_PURCHASER for dates >= 2026-02-01 still resolves to edgex2026PT2, so a 1NN rollover date is needed once purchasing starts (deal target close 2026-07-28).
- `FUNDS.EDGEX_2026_1 = 'edgex20261NN'` already exists and is in EDGEX_FUNDS.

Ref: https://edgefocuspartners.slack.com/archives/C08J572GQBE/p1782766983577449?thread_ts=1782766983.577449&cid=C08J572GQBE

## Log
- 2026-07-28T11:42Z [claude-code] Asked Nate/Trishit in the group DM (C0BJ1M304BU, 2026-07-28 17:06 IST). Trishit replied 17:08: 'Don't think any actions are needed on this. This is generally a constant defined in our codebase to populate in internal tables.' Nate has not replied.

Reading: the investor ID is NOT something Oliv will send — it's a label we stamp per fund on our side, so we are not blocked waiting on a tape change. But this does NOT clear the real code gap: northpond/constants.py FUND_WITH_PURCHASE_TAPE_EXPR hardcodes FUNDS.EFHYF for ANY loan appearing on silver.northpond_stmt_purchase_tapes with PURCHASE_DATE <= AS_OF_DATE. If EDGEX 2026-1NN Oliv purchases arrive on that same purchase tape, they will be labelled efhyf, not edgex20261NN. Needs a follow-up asking how the EDGEX purchases arrive (same purchase tape / separate file / separate SFTP account) — that is the fund-attribution question, separate from the investor ID.
- 2026-07-28T11:49Z [claude-code] Nate Wong replied 2026-07-28 17:14 IST in the same thread:
1. Agrees no entity delineation exists in any reporting to date.
2. Expects effectively ALL loans held by INV103 (Grantor Trust); INV105 is the exception. So the INV103/INV105 split is a 'less critical' gap on Day 1.
3. Oliv has NOT yet extended their Nelnet loan + transaction files to us (prioritization only). These are the equivalent of the files shared today from FCC, their previous servicer. The Nelnet LOAN FILE carries the investor tag — i.e. that feed is what properly solves the INV103/INV105 split.
4. Other post-launch solutions possible depending on use case.
His proposal: (a) everything INV103 by default, (b) punt INV103-vs-INV105 for a couple weeks, (c) start work on sharing the Nelnet loan + transaction files. Asked Abhishek for his view.

STATUS: the investor-ID half is effectively settled — default INV103, no tape change needed now. STILL OPEN: neither Nate nor Trishit addressed EDGEX-vs-EFHYF fund attribution, which is the urgent one since purchasing starts today and FUND_WITH_PURCHASE_TAPE_EXPR hardcodes efhyf for every loan on the Oliv purchase tape.
- 2026-07-28T12:19Z [claude-code] RESOLVED (Abhishek, 2026-07-28): all Oliv loans purchased from today onward belong to the EDGEX fund, so there is no EDGEX-vs-EFHYF discriminator needed on the purchase tape and no question to ask Oliv. The fund split is a DATE CUTOFF we own: purchase-tape loans with PURCHASE_DATE < 2026-07-28 -> efhyf, >= 2026-07-28 -> edgex20261NN.

Remaining code work: FUND_WITH_PURCHASE_TAPE_EXPR in edgefocus/transformations/silver/statement_rows/northpond/constants.py currently returns FUNDS.EFHYF unconditionally for any loan on silver.northpond_stmt_purchase_tapes with PURCHASE_DATE <= AS_OF_DATE. Needs the date-based branch. Caveat to confirm with Trishit eventually: a pure date rule breaks if EFHYF resumes buying Oliv loans later.
- 2026-07-28T17:40Z [claude-code] CODE STATE RE-VERIFIED ON MASTER 2026-07-28 — still genuinely open, and this is today's live risk. Read edgefocus/transformations/silver/statement_rows/northpond/constants.py at origin/master: FUND_WITH_PURCHASE_TAPE_EXPR is unchanged and still returns FUNDS.EFHYF unconditionally for any loan whose LoanNumber appears on silver.northpond_stmt_purchase_tapes with TRY_TO_DATE(PURCHASE_DATE) <= AS_OF_DATE. There is no date branch and no open PR touching it (checked all of Abhishek's PRs).
So the rule settled on 2026-07-28 — purchase-tape loans before today -> efhyf, on or after today -> edgex20261NN — exists only as a decision, not as code, while EDGEX 2026-1NN purchasing starts today. Every Oliv loan purchased from now on will be labelled efhyf until this lands.
The investor-ID half remains settled per Nate (default INV103, no tape change needed), so this item is now purely the fund-attribution code change.
