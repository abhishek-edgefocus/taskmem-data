---
id: wm-ytaxsk
type: task
title: Purchase tape lands before the Nelnet positions feed - northpond_transfers fails ~daily until it catches up
status: next
priority: p1
size: s
due: 2026-09-03
tags: [northpond, edgex]
created: 2026-09-01T11:35:00Z
updated: 2026-09-03T15:07:20Z
source: claude-code
---

## Log
- 2026-09-02T19:36Z [claude-code] LINEAR TICKET IDENTIFIED (2026-09-03): this is ERROR-1626 (https://linear.app/edge-focus/issue/ERROR-1626, Sentry EFP-ERRORS-1JB, assignee Abhishek, priority Low, labels Dagster + Data Ingestion). Currently OPEN — reopened 2026-09-01 19:27Z.

The ticket is FLAPPING, which is why it keeps resurfacing: Done -> Backlog six times now (07-19, 08-19, 08-29 20:27, 08-31 21:32, 09-01 15:29, and reopened again 09-01 19:27). Sentry auto-reopens it on each regression, so closing it by hand does not stick while the underlying ~daily failure continues.

Last 7d of EFP-ERRORS-1JB events are all Steps failed: ['northpond_transfers'] — 09-01 09:50, 09-01 13:37, 09-01 18:49, 09-02 11:49, 09-02 13:14, 09-02 18:52 — plus two 'Exceeded maximum runtime of 7080 seconds' runs on 08-29 14:20 and 08-31 16:33 (worth checking whether the timeout is the same tape-vs-positions lag stalling the step, or a separate problem).

Cadence matches this item's thesis exactly: ~2-3 failures/day, clearing and recurring rather than failing permanently.

NOTE the ticket will keep auto-reopening until either the ordering is fixed or the alert is tuned — so 'is it closed' is not a useful signal for this one. See also [[wm-hjbt5a]] (records northpond_transfers ValueError: Validation failed with 1116 error(s)) and the correction [[wm-85vvgw]] (ERROR-1626 is NOT the .efp_toplevel defect in [[wm-te4cr2]]; that one still has no Linear ticket at all).
- 2026-09-03T15:07Z [claude-code] LIVE INCIDENT as of 2026-09-03. The northpond STANDARDIZED chain has been down 3 days: silver.positions and silver.transfers both frozen at max 2026-08-31, while the stmt layer is current to 09-03 (nelnet_positions, purchase_tapes, issuance_v2 all 09-03). statements_northpond has failed 7 consecutive runs since 2026-09-01 09:48; last success 2026-08-31 20:19. Failing step is northpond_transfers, ValueError: Validation failed with N errors, N growing 17 -> 17 -> 27.

IT DOES NOT SELF-CLEAR (my earlier call was wrong). northpond_positions lists northpond_transfers in its deps, so a transfers failure SKIPS positions - the chain cannot catch up on its own. Deadlock.

Servicer tape HAS caught up: of the loans on the 09-01/02/03 purchase tapes, 0 are absent from northpond_stmt_nelnet_positions. But for 09-01, 17 loans were first seen by the servicer AFTER the tape date, so a transfers re-run for 09-01 may still fail on event ordering (purchase dated after the transfer). 09-02 and 09-03 tapes are clean - every loan was on the servicer tape by the tape date.

SUGGESTED UNBLOCK (untested): materialize northpond_transfers with as_of_date 2026-09-02:2026-09-03 first (should pass), which unblocks northpond_positions; then handle 09-01's 17 separately.

KNOCK-ON THAT MATTERS: loans_in_fund pins EDGEX membership to MAX(transfer_date WHERE to_fund='edgex20261NN'), which is now frozen at 08-31 again. That is exactly the mechanism behind Trishit's item 5 on the EDGEX deployment dashboard. Do NOT tell Sean/Trishit the Oliv issues are fully fixed while this is open. Also failing in the same job, separately and already tracked: northpond_api_predictions and northpond_exp_predictions, both 'no GitHub token / .efp_toplevel not found' - see [[wm-te4cr2]].
