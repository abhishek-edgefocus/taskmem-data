---
id: wm-ufw7kj
type: task
title: Investigate NULL/missing Clarity attributes in the Experian Activate model container (DEV-1490)
status: next
priority: p2
size: m
people: [Nate]
tags: [northpond, experian-activate, api-health]
links: [relates:wm-mmmc9t, follows:wm-9dx47e, parent:wm-d3qnqe]
refs: [DEV-1490=https://linear.app/edge-focus/issue/DEV-1490/investigate-how-the-northpond-experian-model-container-handles-null]
created: 2026-07-31T12:54:52Z
updated: 2026-08-27T14:25:33Z
source: claude-code
label: Activate NULL Clarity attributes
---

Created by Abhishek 2026-07-30 13:48Z off the Activate early-results discussion with Nate
([[wm-9dx47e]], now done). Linear DEV-1490, Todo, unstarted, branch name reserved.

THE FINDING (Nate's, as recorded on the ticket):
- Experian sometimes returns **all Clarity attributes NULL** in the Activate marketing
  environment.
- Those consumers apply with far worse credit grades than expected — likely explains the
  variance Nate saw in the early results.
- **PROD rejects on missing attributes, but the hosted Activate model still returns
  scores.** That divergence is the core of it: the marketing path is scoring applicants the
  production path would refuse, so Activate targeting is being driven by scores computed on
  incomplete input.

WHY THIS IS AWKWARD RIGHT NOW: the container in question is the one Abhishek has just taken
over from Nakula and has **not yet had a formal KT on** — see [[wm-mmmc9t]]. Understanding
how the packaged model handles NULL attributes is close to the first real question anyone
would ask of it, so this and the KT should probably happen together rather than in sequence.

Open, unscoped: whether the fix is in the container (reject/flag like PROD), in what
Experian sends, or in how Activate consumes the score.

## Log
- 2026-08-27T14:25Z [claude-code] DEV-1490 investigated from scratch 2026-08-27 against master 9b9e0b0c3 — the 2026-07-29 analysis was partly stale and its headline numbers were wrong. WHAT IS TRUE NOW (all re-derived): (1) PROD gate is absolute — any missing feature and the model is never invoked, creditGrade=null. 186,163 August endpoint_transactions, ZERO exceptions: complete 176,122 (0 null), both-blocks-missing 6,654, CLARITY-ONLY-MISSING 2,265 (1.2%), creditReport-only 1,122. No model_requests event exists for any missing-feature case. (2) Clarity is ALL-OR-NOTHING — missing count is always exactly 49 or 0, never partial. Nate's 'all Clarity attributes NULL' is literally correct. (3) The container (experian/app.py) has NO completeness check, parses null/NULL/None to NaN, and extracts credit_grades at line 319 BEFORE the decision filter at line 337, so even a refused row returns a grade. NULL_PER_LOAN=0.5 never fires (49/207=23.7%) and only sets decision=False, never nulls credit_grade. (4) COST, on a harness first validated by reproducing PROD's actual returned creditGrade 4,000/4,000 EXACTLY: median grade 51 -> 23 with Clarity blanked, mean 53.9 -> 27.3, 96.5% get a BETTER grade, median move -24, 81.5% move >=10. Cutoff grade<=15: pass 6.1% -> 25.2% (x4.1), false-pass 19.1%. Sentinel 999999 is not a fix either (median 30). CORRECTIONS TO THE JULY PASS: it claimed both paths share one artifact — FALSE, they are two distinct pickles (container northpond_exp_docker_model_lgbm.2026-01-28, PROD northpond_exp_model_lgbm.2026-01-15v2, distinct since Jan 2026) that happen to score IDENTICALLY on 4,000 rows (100%), so the conclusion 'the difference is the gate not the model' survives but for a different reason. Its impact numbers (81.2% better, median -4, cutoff 43.3%->60.4%) were computed on the training population, not live traffic — live median grade is 51, not 18. STILL UNVERIFIED: the July claim that training loans with genuinely-absent Clarity default less (5.0% vs 10.4%), i.e. the model learned no-Clarity=prime. Not re-derived; must be re-checked before it drives the fix. Written up as finding 13 in ~/notes/areas/efp/platforms/northpond/findings.md with meta.md stamped. Linear comment drafted for Abhishek to paste; nothing posted.
