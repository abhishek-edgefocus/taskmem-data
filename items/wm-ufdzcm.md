---
id: wm-ufdzcm
type: bug
title: EDGEX 261 dashboard: NorthPond principal balance drops ~800K -> ~400K against ~8,005K cumulative principal purchase
status: open
priority: p2
size: s
tags: [northpond, edgex]
links: [parent:wm-d7m3xz]
created: 2026-08-19T21:47:21Z
updated: 2026-08-19T21:47:36Z
source: claude-code
---

## Log
- 2026-08-19T21:47Z [claude-code] From the 2026-08-20 EdgeX dashboard review. For EDGEX 261 broken down by platform, NorthPond cumulative principal purchase is ~8,005K but the corresponding principal balance drops unexpectedly from ~800K to ~400K. The upgrade-related issue in the same view is already corrected; this one is not. IMPORTANT: several downstream dashboard graphs are expected to self-correct once principal balance is right, so fix this BEFORE chasing the E3/E4 mix ([[wm-faurta]]) - the 60/40 split should only be flagged to Eric once the principal balance is confirmed correct. Also check whether the to-be-purchased filter discrepancy (with vs without the filter) affects NorthPond only or other platforms too. Related: [[wm-uxwcxn]] is the same to-be-purchased population from the data side.
