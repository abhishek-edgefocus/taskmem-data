---
id: wm-wtqfcn
type: task
title: Reply to Sean in #data-discussion: Oliv issues 4 & 5 on the EDGEX deployment dashboard + fix timeline
status: next
priority: high
due: 2026-09-01
tags: [northpond, edgex, dashboards, oliv]
links: [relates:wm-39q8fh]
created: 2026-08-31T16:46:27Z
updated: 2026-08-31T17:12:04Z
source: claude-code
estimate: <1h
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

## Log
- 2026-08-31T17:12Z [claude-code] PROD VERIFIED 2026-08-31. Ran the wm-39q8fh intended-vs-shown check day by day 08-18..08-31 (PROD, via dpx).

1) The stranding bug is GONE and never came back: GAP = 0 on every date, and CURRENT_N == OWNED_N on every date. Trishit's items 4/5 were raised 08-25, a day the data was provably clean (intended 474 = owned 296 + TBP 178). So items 4 and 5 are almost certainly dashboard-reading artifacts: item 4 = the to-be-purchased toggle (what Kushagra told him), item 5 = the natural TBP saw-tooth as loans leave the pending bucket on purchase (TBP principal 407K/394K/398K/378K/433K/475K/425K/477K/442K/378K/383K/387K/423K/455K).

2) Kushagra's #6451 (DEV-1659, merged 08-26) did NOT fix items 4/5 - there was no gap in that window to fix. My earlier attribution was wrong.

3) A DIFFERENT, live gap exists: 19 northpond loans / $55,598 are stamped FUND='edgex20261NN' in silver.positions since 08-29 but have no row in silver.loans_in_fund for that fund. They ARE in loans_in_fund under to_be_purchased_edgex20261NN and northpond_balancesheet. TBP membership is complete (175/175). Other platforms clean (upgrade 1 loan at $0).

ROOT CAUSE (confirmed, not a loans_in_fund defect): EDGEX membership comes from build_final_loan_set_sql in edgefocus/transformations/gold/warehouses/cndr.py, which freezes membership at prefunding_end_date = MAX(transfer_date) WHERE to_fund='edgex20261NN' in silver.transfers, and observes each platform at LEAST(cutoff, its own MAX(as_of_date)). Today the cutoff is 2026-08-28, so northpond is observed at 08-28 where owned = 387; positions today has 406. 406 - 387 = 19 exactly. loans_in_fund_job is healthy (SUCCESS 17:02 UTC today), so this is logic, not staleness.

Why the cutoff is stuck: no transfers into edgex20261NN since 08-28 (Fri). 08-29/08-30 are Sat/Sun; 08-31 (Mon) has not landed yet. It self-heals the moment a new transfer advances the cutoff.

4) Eshan's #6433 is NOT the candidate - it changes the observation semantics, not the cutoff. Do not chase it for this.

5) SEPARATE finding worth its own look: northpond's own transfer rows into edgex20261NN stop at 08-21 (only 65 northpond loans have any: 31 on 08-20, 34 on 08-21). 122 loans currently in membership have no transfer row at all. So the cutoff that governs northpond's inclusion is driven entirely by OTHER platforms' transfer activity. Fragile.

6) Sean's "no-breakdown view stuck at 8/24" is HappyMoney, not Oliv: max as_of_date among EDGEX-tagged rows is northpond 08-31, prosper 08-31, upgrade 08-31, happymoney 08-24. happymoney's obs_date is 08-24 - DEV-1659 behaving as designed.

Scripts on dpx: ~/q_gap.py, ~/q_19.py, ~/q_cutoff.py, ~/q_19b.py, ~/lif_runs.py (run from ~/claude-ws/dev-1490/efp with .env sourced).
