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
updated: 2026-07-28T11:42:15Z
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
