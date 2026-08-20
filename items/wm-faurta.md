---
id: wm-faurta
type: question
title: Check EDGEX E3/E4 origination mix with Eric - dashboard shows ~60/40, expectation was ~90/10
status: next
priority: p2
size: xs
due: 2026-08-21
people: [Eric]
tags: [northpond, edgex]
links: [parent:wm-d7m3xz]
created: 2026-08-19T21:47:21Z
updated: 2026-08-20T17:26:39Z
source: claude-code
---

## Log
- 2026-08-19T21:47Z [claude-code] From the 2026-08-20 EdgeX dashboard review. Dashboard shows ~2.7-3% E3 and ~1.9% E4, read as roughly a 60/40 split; the expectation recalled from Eric was ~90/10. GATED: do not raise with Eric until the principal-balance bug [[wm-ufdzcm]] is fixed, since the percentages are computed on principal balance (E2+E3+E4 = 100% of principal balance across ALL platforms - looking at Oliv alone was the source of earlier confusion). The E3/E4 numbers themselves are no longer inflated after the backfill and now reconcile (~1.43% + ~1% = ~2.4% against ~19.8 cumulative deployed principal).
