---
id: wm-c4w87n
type: task
title: NorthPond follow-up: to-be-purchased partition rewrite + outage-aware gap alarm (branch abhishek/northpond-partition-intent)
status: dropped
priority: normal
tags: [northpond, edgex, data-quality]
links: [relates:wm-39q8fh]
created: 2026-08-20T19:27:42Z
updated: 2026-08-22T07:54:38Z
source: claude-code
estimate: half-day
---

Split out of PR #6394 on 2026-08-20 after review pushback from Abhishek. The
work is committed and pushed on branch `abhishek/northpond-partition-intent`
(commit 8174e2638) but has **no PR** yet, and must not get one until the
issues below are addressed.

## Why it was split out

The reviewer asked me to prove commit 2 was necessary and I could not. Checked
across 2026-08-14 → 08-20:

| Check | Result |
|---|---|
| Loans with `CURRENT_INVESTOR='edgex20261NN'` but no row on either servicing tape | **0 on every date** |
| The 31 loans stranded on 08-20 | all 31 on a tape with `FUND='northpond_balancesheet'` |
| Does the re-stamp propagate? | yes — `northpond_positions` sources both tapes (positions.py:219-220) |

So every stranded loan has a tape row for the commit-1 stream fix to re-stamp,
and the chain converges in one run (tape → positions → to_be_purchased, with
to_be_purchased triggered by the same issuance_v2 change). It is a
convergence-lag defect, not a membership-semantics defect. The predicate
rewrite defends a state that has never occurred.

**Do not revive this as-is.** If it comes back it needs a real trigger — e.g.
a loan whose CURRENT flips while it is on no tape, which would be structurally
unattributable. Watch for that case appearing before spending more on it.

## Must fix before this branch becomes a PR

1. **Constant drift (reviewer's #2).** The new gap ValidationRule hardcodes
   `'{FUNDS.NORTHPOND_BALANCESHEET}'` instead of reusing
   `_BALANCE_SHEET_FUNDS_SQL`, which is what the predicate it polices uses.
   The pre-existing overlap rule does the same thing — I copied the pattern
   rather than fixing it. The constant is plural because the set is meant to
   grow; a rule that can drift from the transform it validates is worse than
   no rule. Fix in BOTH places.

2. **Staleness blind spot (reviewer's #3).** `STALE_DAYS = 3` gates both
   membership and the gap rule, so the alarm shares the blind spot of what it
   alarms on. Simulated at `as_of 2026-08-20` against prod:

   | outage day | would-be pending | survives stale gate | dropped silently |
   |---|---|---|---|
   | 0 | 159 | 159 | 0 |
   | 1 | 154 | 154 | 0 |
   | 2 | 167 | 167 | 0 |
   | 3 | 160 | 160 | 0 |
   | **4** | **165** | **0** | **165** |

   It is a cliff, not a decay: on day 4 of an issuance outage the entire
   pending population leaves deal totals in one step and the gap rule is
   silent at exactly that moment. Oliv has missed a day once (2026-08-04).
   Needs an outage-aware trigger — alarm on issuance_v2 absence itself,
   independent of STALE_DAYS — not a longer bound.
   NOTE: the membership half of this is PRE-EXISTING and ships today. It is
   worth fixing on its own even if the partition rewrite never lands.

3. `test_gap_check_honours_the_staleness_bound` pins the bound in but does not
   test the outage. Needs a test for the day-4 case.

Related: wm-39q8fh (the shipped fix, PR #6394).

## Log
- 2026-08-22T07:54Z [claude-code] Dropped 2026-08-22 on Abhishek's call. Two pieces were parked here: (1) the to_be_purchased partition rewrite on branch abhishek/northpond-partition-intent — already judged not worth reviving, since it defends a state (CURRENT_INVESTOR flipping while the loan is on no tape) with zero observed occurrences; (2) the STALE_DAYS=3 outage cliff, where a 4-day issuance gap would silently drop the whole pending population AND silence the gap check. Abhishek's judgement: a 3-4 day issuance outage is not realistic — the one real gap (2026-08-04) was a single day, and PR #6394 handles the same-day race that actually happens. Closing rather than carrying it. If issuance ever goes missing for multiple consecutive days, reopen this and build an alarm on file absence itself, independent of STALE_DAYS.
