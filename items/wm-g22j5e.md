---
id: wm-g22j5e
type: followup
title: Give Trishit inputs on PR #6082 (oliv_exp_statement_model) + the Dagster wiring discussion
status: next
priority: p1
size: xs
due: 2026-07-31
people: [Trishit, Nakula, Sean]
tags: [northpond, needs-reply]
links: [relates:wm-9s2mwd, relates:wm-j2prpv]
refs: [PR6082=https://github.com/edgefocus/efp/pull/6082, sean-thread=https://edgefocuspartners.slack.com/archives/C06RMEK095G/p1785264036485469]
created: 2026-07-29T13:42:21Z
updated: 2026-07-31T12:55:41Z
source: claude-code
label: PR 6082 oliv statement model
---

RESOLVED SINCE THIS ITEM WAS OPENED (2026-07-29): Trishit took the work, and Sean's
"put it in a real model object" ruling has been implemented as **PR #6082** —
`oliv_exp_statement_model: retarget + ANL floor as a real model artifact`. Status on
2026-07-31: **APPROVED, still open**. Discussion is happening in the new group DM
C0BLXJE8534 (Trishit, Abhijeet, Nakula, Abhishek).

THE AMBIGUITY THIS ITEM FLAGGED IS ALSO RESOLVED: Sean's "statement model" is genuinely a
STATEMENT-side model and is **not** DEV-1452/QR-23 (the purchase-tape model, [[wm-9s2mwd]]).
They are separate pieces of work.

WHAT PR #6082 ACTUALLY DOES — worth reading before replying, because it changes what
DEV-1445 shipped:
- Registers `oliv_exp_statement_model` in models_by_channel.json as a real serialized
  artifact resolved by model_name + git tag, satisfying `ModelProtocol` (patterned on
  `prosper_cde_statement_model`).
- `predict()`: `target = max(oliv_anl if published else our_anl, 6.5%)`, `k = target/our_anl`,
  `default' = clamp(default*k, 0, 1)`, prepay untouched. **The 6.5% ANL floor is new policy**
  — it sits just above the ~6.31% E2/E3 boundary so every exp loan grades minimally E3, and
  it is applied by scaling the curve, never by clamping the ANL.
- **Reverts the inline retarget in `northpond_api_predictions.py` and gates it to
  `api_version=1`**, so exp predictions come only from the model. Exp at_orig moves
  `source='api'` -> `source='s3'`.
- Renames the model in `silver.predictions` from the gateway `northpond_exp` to the Oliv
  statement model — Trishit's deliberate choice so the owned portfolio can be fetched
  directly rather than matched via IDs, and he explicitly asked whether the dev team is OK
  with it.

TWO OPEN ASKS DIRECTED AT ABHISHEK:
1. Trishit, 2026-07-31 16:36 IST: "I have a comment in the last of this updated PR as a
   reply to one of the bots where I'd need your inputs" (@-ing Nakula and Abhishek).
2. Trishit, 2026-07-31 02:34 IST: "had to make changes to the structure here so let's
   connect tomorrow to discuss what else needs to be done. Claude mentioned addition to some
   Dagster assets and all so I'll rely on your expertise on the subject" — i.e. the Dagster
   wiring is the part he wants Abhishek to own.

RISK TO RAISE IF NOBODY HAS: the PR's own verification section says the generator, the
transform revert and the Dagster wiring were **not run** on the authoring box, and that
**shipping the v1-only gate without the generator scheduled would drop exp at_orig rows**.
It also requires a parity gate (generated curves bit-match the old inline retarget on the
same inputs) before promotion. Approved is not the same as safe to merge here.

Nakula's read (C0BLXJE8534, 2026-07-30): largely a refactor; no predictions are actually
made from the model, its only purpose is to mark in silver.predictions that these are not
gateway-derived; no downstream Snowflake consequences beyond the model name. He suggested a
helper in `northpond_api_predictions.py` might do instead of a separate
`oliv_exp_statement_model.py` — Trishit disagreed, wanting tagging and version control.

Knock-on for two existing items: [[wm-etzegu]] (alert on silent k=1 retarget fallback) and
[[wm-vye9hn]] (force ef_scores re-derive of the 33 stale loans) were both written against
the inline SQL retarget this PR removes.

## Log
- 2026-07-31T12:55Z [claude-code] REFRAMED 2026-07-31: created as 'get back to Trishit on ownership + Sean's ruling'. Both halves are now settled — Trishit owns it and has shipped PR #6082 (APPROVED, open), and Sean's 'statement model' is confirmed statement-side, not the purchase tape. The item is retitled to what is actually still owed: inputs on his bot-reply comment (asked 2026-07-31 16:36 IST) and the Dagster-wiring discussion he explicitly wants Abhishek to drive (asked 2026-07-31 02:34 IST). Due set to today since both asks are from today and one is 2 days old.
