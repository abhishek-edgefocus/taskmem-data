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
updated: 2026-09-03T19:43:27Z
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
- 2026-09-03T19:41Z [claude-code] SURVEY (2026-09-04, transfers-survey subagent): northpond ALREADY has the fix, on branch abhishek/northpond-transfers-event-type-join at dp:~/claude-ws/northpond-transfers-fund/efp, commit ec08ccaaa 'Fix northpond transfers dropping the origination purchase for same-day sales' (98 insertions, transfers.py only; working tree clean; not on main in that checkout). Three stacked defects fixed: (1) generate_sql now passes tape_event_type_expr='t.TAPE_EVENT_TYPE' (transfers.py:373) so tape/first_pass no longer collapse a same-day purchase+transfer into one row; (2) first_pass AS_OF is now LEAST(positions AS_OF, MIN purchase-tape AS_OF) (transfers.py:245-248, 273-277) so the purchase and its transfer land in the same single-date run scope; (3) NEW tape-derived second arm on _inferred_purchases_leg (transfers.py:286-332) synthesizes the origination purchase straight from silver.northpond_stmt_purchase_tapes (FUNDING_DATE, LOAN_AMOUNT) when the servicer has not reported the loan yet, deduped one-per-loan with the servicer arm preferred via SRC_RANK QUALIFY (transfers.py:334-336). Arm 3 is the reusable pattern other platforms should copy. GAP: transfers_test.py has NO test for any of the three; existing tests only cover the INFERRED_PURCHASE_DATE_EXPR clamp.
- 2026-09-03T19:43Z [claude-code] Cross-platform survey (marlette leg): marlette is NOT exposed to the northpond failure. Its origination purchase comes from the purchase tape itself (silver.marlette_stmt_{fortress_,}purchase_tapes via _tape_cte, transfers.py:382-414); EVENT_TYPE defaults to 'purchase' for any tape row with no sheet row (transfers.py:327). Its stmt_positions first-occurrence leg is a LOW-PRIORITY orphan-loan fallback only (IS_INFERRED=TRUE, transfers.py:136-167,375-378). Reusable pattern found: marlette/to_be_purchased_positions.py already solves the same feed-timing race on the POSITIONS side - the origination file names a committed loan a 10-day median (max 38) before loanhistory boards it; it emits a synthetic to_be_purchased_<fund> position from the delivery date until FIRST_OWNED_DATE (first loanhistory date with SEASONING_PURCHASE_DATE <= AS_OF_DATE, NOT bare presence), capped by GRACE_DAYS=14 off the scheduled PURCHASE_DATE, with a blocking to-be-purchased-not-also-owned XOR validation. That bounded, explicitly-flagged pre-settlement state is the pattern to consider adopting for northpond transfers.
