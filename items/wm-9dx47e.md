---
id: wm-9dx47e
type: followup
title: Discuss Nate's early-results analysis on the Experian Activate model
status: waiting
priority: p3
size: s
waiting_on: Nate
nudge: 2026-08-03
people: [Nate]
tags: [northpond, experian-activate]
links: [relates:wm-mmmc9t]
refs: [dm=https://edgefocuspartners.slack.com/archives/D0BAD46CT27/p1785338639008019]
created: 2026-07-29T15:32:47Z
updated: 2026-07-29T16:24:08Z
source: claude-code
label: Nate Activate early results
---

Nate DM, 2026-07-29 20:53 IST (D0BAD46CT27): after confirming Abhishek has taken over the
Experian Activate dockerised model, he added — "Asking because I have a follow-up topic
regarding some analyses we've been doing on early results." He explicitly framed it as
**not urgent**: "don't distract from other EdgeX matters".

Abhishek replied 21:00 IST: "...I haven't had a formal KT yet, so my understanding is still
fairly limited, but I'd be happy to discuss the analysis and see how I can help."

So the ball is with Nate — he has not yet said what the topic is. This sits in `waiting`
until he raises it.

WORTH DOING FIRST if it becomes live: the KT from Nakula on [[wm-mmmc9t]]. Abhishek has
already told Nate his understanding of the container is limited, so a substantive analysis
conversation before the KT will be shallow.

## Log
- 2026-07-29T16:24Z [claude-code] Ran the NULL-Clarity analysis 2026-07-29 without needing Experian or the KT. FINDINGS: (1) Clarity = 49 of 207 model features (24%). (2) PROD treats a NULL attribute value as missing (extract_clarity_attributes in lib/efp/experian_data/helpers.py) and skips scoring entirely if ANY of the 204 is missing -> creditGrade=null. The Activate container (lib/efp/json_endpoints/platforms/api/northpond/experian/app.py) has NO completeness check at all, so a grade always comes back. Same model artifact both sides (northpond_exp_docker_model_lgbm.2026-01-28); the difference is the gate, not the model. (3) The models 50% null_per_loan safety gate never fires at 49/207 = 23.7% null, and it only flips decision=False - it does not null credit_grade, which app.py reads before filtering on decision. (4) credit_grade = ceil(agl*100) clipped 1-100 = predicted annualised GROSS LOSS, so LOWER grade = BETTER credit. (5) Blanking all 49 Clarity attrs for 3000 consumers whose real Clarity we know: 81.2% get a BETTER (lower) grade, median -4, mean -5.9, 22.4% move >=10 points, spearman 0.875. At a grade<=15 targeting cutoff, pass rate goes 43.3% -> 60.4% with 18.4% false-passes. (6) The model is NOT wrong about the natural population: training loans with genuinely absent Clarity (32% of 869k loans) defaulted at 5.0% vs 10.4% for real-Clarity loans, and the model scores them median 7 vs 18. The learned prior is no-Clarity-footprint = prime consumer. RISK: in Activate, NULL likely means an Experian data gap, not an absent footprint - the model cannot tell them apart and applies the optimistic prior, which is a clean explanation for Nates observation that these consumers apply with far worse grades than expected. Also found: training already contains BOTH encodings - 32% true NaN and 38% sentinel-coded (99/999999), so sentinel values are not a safe alternative either (median grade 13 vs 18). Abhishek sent Nate a short reply asking only for the test files + returned grades; no findings shared yet.
