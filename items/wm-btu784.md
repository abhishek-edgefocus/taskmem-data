---
id: wm-btu784
type: task
title: Oliv ANL retarget: finish the prediction chain and stop it silently falling back
status: active
size: xl
people: [Trishit, Nate]
tags: [northpond, predictions]
links: [parent:wm-d7m3xz]
refs: [DEV-1445=https://linear.app/edge-focus/issue/DEV-1445/retarget-northpond-at-orig-cashflows-to-olivs-anl]
created: 2026-08-14T14:54:38Z
updated: 2026-08-14T19:56:17Z
source: claude-code
label: Oliv ANL prediction chain
---

Container for everything still outstanding from the DEV-1445 Oliv-ANL retarget and Trishit's
PR #6082 predictor restructure. Created 2026-08-14 while restructuring the memory into ordered
threads; the members already existed but the ordering between them lived only in prose inside each
one, where it was easy to miss.

THE ORDERING IS LOAD-BEARING HERE — running these out of sequence produces wrong numbers rather
than just wasted effort:

1. The Dockerfile fix comes first because `northpond_exp_predictions` has failed on EVERY prod run
   since 2026-08-05 (AssertionError: .efp_toplevel not found). It dies before it reads any data,
   so the exp at_orig slice has NEVER been written.
2. The artifact/re-run sequence is therefore stalled at its step 3, and its own body is explicit:
   do not run `northpond_api_predictions --date all` (which deletes 4,860 stale source='api' rows)
   until the asset actually materializes, or exp loans are left with no at_orig row at all.
3. The ef_scores re-derive goes last because the model introduces a 6.5% ANL floor that did not
   exist when those 33 loans were scored. Re-deriving today and re-deriving after the exp slice
   lands give DIFFERENT numbers, so doing it early means doing it twice.

Running alongside, not in the chain: the 1.36 gross-vs-net question to Nate (one Slack message,
on the critical path since 2026-07-21 and still unsent) and the fallback alerting Trishit asked
for on 2026-07-27.

## Next steps
- Render the order with `taskmem chain` on this item (id is in the frontmatter above).
- The unblocked step is the one-line Dockerfile fix for ERROR-1626.
- Send the 1.36 question to Nate regardless of where the chain is — it costs one message and it
  biases k.

## Links
- DEV-1445 — https://linear.app/edge-focus/issue/DEV-1445/retarget-northpond-at-orig-cashflows-to-olivs-anl
- Retarget PR #6015 — https://github.com/edgefocus/efp/pull/6015
- Predictor restructure PR #6082 — https://github.com/edgefocus/efp/pull/6082
- Project: [[wm-j523sq]]
