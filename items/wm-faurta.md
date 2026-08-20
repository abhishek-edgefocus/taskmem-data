---
id: wm-faurta
type: question
title: Check EDGEX E3/E4 origination mix with Eric - dashboard shows ~60/40, expectation was ~90/10
status: next
priority: p2
size: xs
people: [Eric]
tags: [northpond, edgex]
links: [parent:wm-d7m3xz]
created: 2026-08-19T21:47:21Z
updated: 2026-08-20T18:55:49Z
source: claude-code
---

## Log
- 2026-08-19T21:47Z [claude-code] From the 2026-08-20 EdgeX dashboard review. Dashboard shows ~2.7-3% E3 and ~1.9% E4, read as roughly a 60/40 split; the expectation recalled from Eric was ~90/10. GATED: do not raise with Eric until the principal-balance bug [[wm-ufdzcm]] is fixed, since the percentages are computed on principal balance (E2+E3+E4 = 100% of principal balance across ALL platforms - looking at Oliv alone was the source of earlier confusion). The E3/E4 numbers themselves are no longer inflated after the backfill and now reconcile (~1.43% + ~1% = ~2.4% against ~19.8 cumulative deployed principal).
- 2026-08-20T17:26Z [claude-code] 2026-08-20: Abhishek asked to be reminded TOMORROW (2026-08-21) to chase the expected E3/E4 ratio - due date set so it surfaces in the session-start digest. STATE AS OF TODAY: our dashboard reads ~60/40 (E3 ~2.7-3%, E4 ~1.9% of total principal balance); the 90/10 expectation is RECALLED FROM ERIC and has never been confirmed by him directly. Draft prepared for Nate: 'Hey Nate - on the E3/E4 mix: we're seeing the ratio come out at roughly 60/40 on our side, but what we'd heard was that it's expected to be around 90/10. Can you confirm which is right?' NOT SENT as of 2026-08-20. Two caveats to re-read before sending: (1) Nate may not be the right person - the 90/10 came from Eric; (2) our 60/40 rests on the principal-balance figure that [[wm-ufdzcm]] says is wrong, so a 90/10 confirmation would not yet prove a real discrepancy on Oliv's side.
- 2026-08-20T17:28Z [claude-code] CORRECTION 2026-08-20: the previous entry's 'remind me tomorrow / due 2026-08-21' was a speech-to-text misread on my part - Abhishek never asked for a reminder, he asked for the question to Nate to be rephrased as OPEN-ENDED (ask what the expected ratio is, rather than asserting 90/10 and asking for confirmation). Due date cleared; there is no 2026-08-21 commitment on this item.
- 2026-08-20T18:55Z [claude-code] 2026-08-20 IST: asked Nate in DM at 22:59 (60/40 ratio, is it expected?); he asked for definitions at 23:06; Abhishek supplied them at 23:51 (E3 = EF score 29-34 / ANL 6.3-12.6%, E4 = 23-28 / 12.6-25.1%). Now waiting on Nate's answer on whether 60/40 is expected. Both supporting sessions are complete and closeable.
