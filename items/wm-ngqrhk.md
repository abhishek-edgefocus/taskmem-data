---
id: wm-ngqrhk
type: question
title: Align backbook terminology with Sean: NorthPond (TU) backbook vs Oliv (Experian) backbook during the EFP transition
status: open
priority: p3
size: xs
people: [Sean]
tags: [northpond, edgex]
links: [parent:wm-d7m3xz]
created: 2026-08-19T21:47:21Z
updated: 2026-08-19T21:47:36Z
source: claude-code
---

## Log
- 2026-08-19T21:47Z [claude-code] From the 2026-08-20 EdgeX dashboard review. Terminology is ambiguous while the business transitions between Oliv, NorthPond and EDGEX: 'NorthPond backbook' = the TU-era book (~350-360K loans), 'Oliv backbook' = the Experian-era book. Experimental loans from the TU side were marked NorthPond backbook, but newer loans that are NOT being purchased into EDGEX or the High Yield Fund are also currently mapping to NorthPond backbook and may belong under Oliv backbook instead. Do not assume everything under NorthPond backbook shares a source. Acceptable to leave transitional loans unclassified for now rather than force a wrong backbook label - those are expected to go to HXT once Dustin gets Oliv's balance sheet signed into the EDGEX platforms.
