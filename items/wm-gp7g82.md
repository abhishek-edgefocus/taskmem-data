---
id: wm-gp7g82
type: task
title: Retarget or close PR #6131 — stale draft still based on the merged oliv_exp_statement_model branch
status: inbox
size: s
tags: [northpond, oliv, predictions]
links: [relates:wm-3rsskm, relates:wm-btu784]
refs: [PR-6131=https://github.com/edgefocus/efp/pull/6131]
created: 2026-08-24T12:29:00Z
updated: 2026-08-24T12:29:32Z
source: claude-code
label: PR 6131 retarget or close
---

Abhishek's own PR #6131 ("Source the exp per-loan fields from silver.positions where
available") has been open as a **draft for 24 days** and is blocked on a step its own body
already names. Found by the 2026-08-24 sync sweep; it had no taskmem item and is mentioned
only in passing inside [[wm-g22j5e]] (done), so nothing was tracking it.

**The blocker is mechanical.** The PR is stacked on #6082 and its body says: *"Stacked on
#6082. Based on `oliv_exp_statement_model`, so the diff shows only this change. Retarget to
`master` once that merges."* #6082 (`DEV-1452 oliv_exp_statement_model: retarget + ANL floor
as a real model artifact`) **merged on 2026-08-05**. The retarget never happened — verified
2026-08-24, `baseRefName` is still `oliv_exp_statement_model`, head is
`oliv_exp_positions_source`. mergeStateStatus is CLEAN and there are zero reviewers.

**The work itself is finished and was verified when written.** `_positions_frame` calls the
shared `load_and_enrich_positions` first and falls back to issuance-derived fields only for
loans positions does not have. The point is that `silver.positions` carries the *serviced*
installment while the gateway payload carries the figure *quoted at application*, and
installment feeds the cashflow engine. Measured over 135 loans / 4,860 rows: INSTALLMENT
differs on 2 loans, every other column identical (DEFAULT_PROBABILITY, PREPAY_PROBABILITY,
TERM/RATE/AMOUNT, FIRST_PERIOD_AFTER_EVENT, MOB_ACCOUNTING_DATE, DQ_STRAT_VALUE all zero
diffs). ruff, mypy (924 files) and the predictor/base/run suites were clean.

**Why it may nonetheless be worth closing rather than landing.** The PR's own scope note
says the two sets were disjoint when it was written — 133 loans with an Oliv ANL and no
positions row, 2 with a positions row and no ANL, intersection 0 — and it argued the
fallback was permanent because at-origination predictions always run ahead of the purchase
tape. That premise has since changed materially: as of 2026-08-24, **265 EDGEX loans have
purchase-tape rows** across nine business days (see [[wm-9dfnnt]]), so the positions side is
no longer near-empty. The measured 2-loan blast radius is 24 days stale and should be
re-measured before this is judged low-risk.

Related work in the same area that is still open: [[wm-3rsskm]] (build + promote the
`oliv_exp_statement_model` artifact and re-run northpond_api_predictions) and
[[wm-btu784]] (the ANL retarget prediction chain).

## Next steps
1. Decide: land it or close it. If the diff is still ~2 loans it is nearly free; if the
   intersection has grown, it is a real change to prediction inputs and needs re-validation.
2. If landing: retarget the base branch from `oliv_exp_statement_model` to `master`
   (`gh pr edit 6131 --base master`), confirm the diff still shows only this change, and
   re-run the 135-loan comparison against current data.
3. Take it out of draft and request a reviewer — see [[wm-f7egzv]], Eshan has offered.
4. If closing: say so on the PR so the branch is not left implying pending work.

## Links
- PR #6131 — https://github.com/edgefocus/efp/pull/6131
- PR #6082 (merged 2026-08-05, the base it waits on) — https://github.com/edgefocus/efp/pull/6082
