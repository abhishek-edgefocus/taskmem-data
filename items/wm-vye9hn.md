---
id: wm-vye9hn
type: task
title: Force silver.ef_scores to re-derive the 33 stale Oliv loans after the ANL retarget
status: next
priority: p1
size: s
people: [Trishit]
tags: [northpond]
links: [parent:wm-j523sq, follows:wm-fzbz7m]
refs: [DEV-1445=https://linear.app/edge-focus/issue/DEV-1445/retarget-northpond-at-orig-cashflows-to-olivs-anl]
created: 2026-07-28T17:37:00Z
updated: 2026-07-28T17:37:07Z
source: claude-code
label: Oliv ef_scores stale 33
---

Fallout from the DEV-1445 retarget ([[wm-fzbz7m]], PR #6015, merged 2026-07-27 and verified in
prod 2026-07-28). The retarget itself is correct — all 103 scored Oliv-ANL loans have cashflows
landing 1.01% mean / 0.57% median / 4.67% max off Oliv's ANL, and the 25,812 non-Oliv rows are
byte-identical. But `silver.ef_scores` did NOT follow for 33 of those 103 loans.

## What is wrong
Those 33 loans still carry EF_ANL equal to our **un-retargeted** model ANL — off Oliv's by up to
87% — even though their underlying cashflows ARE retargeted. Roughly **10 of them are currently
sitting in the wrong EF bucket** (E1..E6).

Root cause: ef_scores is lock-once and stream-scoped. The 33 were first scored 2026-07-10
(LOADED_AT 07-10, pre-retarget), and the retarget run's ef_scores pass at 12:07 (which refreshed
55 loans) did not re-derive them. **It will not self-heal** — there is no pending cashflow change
left to retrigger the stream.

Why it matters now: EDGEX 2026-1NN purchasing of Oliv loans started 2026-07-28, and the EF grade
is what the deal consumes.

## Next steps
1. Confirm the 33 in prod: compare `silver.ef_scores.EF_ANL` against the current
   cashflow-derived ANL per loan for platform='northpond', and list the ~10 whose bucket differs.
2. Force ef_scores to re-derive them from the EXISTING cashflows — `as_of_date=all`, or scoped to
   the affected batches. No cashflow rebuild is needed; cashflows are single-generation and correct.
3. Re-verify EF_ANL now matches the retargeted cashflow ANL for all 103, and that no non-Oliv
   loan moved.
4. Decide whether the lock-once behaviour needs a guard so a future retarget cannot silently leave
   stale scores behind — that is a design question for Trishit, not part of this fix.

## Links
- Parent work that produced this: [[wm-fzbz7m]] (DEV-1468 + DEV-1445)
- Retarget PR: https://github.com/edgefocus/efp/pull/6015
- Related alerting follow-up Trishit asked for: [[wm-etzegu]]
- Project: [[wm-j523sq]]
