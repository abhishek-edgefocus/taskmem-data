---
id: wm-4sxy5d
type: task
title: EDGEX 2026-1NN fund attribution and the first live Oliv purchases
status: active
size: xl
people: [Nate, Abhijeet]
tags: [northpond, edgex, backfill]
links: [parent:wm-d7m3xz]
refs: [PR-6209=https://github.com/edgefocus/efp/pull/6209]
created: 2026-08-14T14:54:05Z
updated: 2026-08-14T20:10:01Z
source: claude-code
label: EDGEX fund attribution
---

Container for the thread that starts with the first real EDGEX purchase file (2026-08-11) and ends
when prod reports one fund name per loan, on the right fund, validated. Created 2026-08-14 as part
of restructuring the memory into ordered threads — the members already existed and were scattered
across the NorthPond project with no lineage between them.

WHY THESE BELONG TOGETHER. Two PRs merged on 2026-08-11 (#6208 renaming `experimental` ->
`northpond_balancesheet`, #6209 splitting the purchase-tape fund at 2026-08-01) but neither
migrated existing rows, and the 29 first-ever live EDGEX purchase rows had already been written
before the deploy. So prod simultaneously holds the same fund under two names and the first EDGEX
purchases on the wrong one. Separately, Oliv only added `current_investor` to issuance_v2 on
2026-08-13, leaving 2026-08-11/12 unattributable, which is the sole reason the
`NORTHPOND_EDGEX_PURCHASE_START` date-hack still exists in constants.py.

ORDERING. The backfill is the time-sensitive step and it is genuinely gating: the 29 purchased
loans have not yet appeared in `silver.northpond_stmt_positions` (Nate: "there can be a few day
delay to get into the NN file"). The moment they do, positions evaluates the NEW fund expression
while transfers reads the tape's STORED old value, and the two disagree. Rebuilding the tape first
avoids the disagreement instead of repairing it — and the purchase-tape validation cannot be
signed off while the tape stores the wrong fund, which is why it sits behind.

The two asks of Nate carry external lead time, so they run in parallel rather than in the chain.

## Next steps
- Run the chain: `taskmem chain wm-8w4ntq --oneline`.
- The unblocked step is the silver backfill; start with rebuilding
  `silver.northpond_stmt_purchase_tapes` at as_of 2026-08-11.

## Links
- PR #6208 (fund rename) — https://github.com/edgefocus/efp/pull/6208
- PR #6209 (EDGEX date split) — https://github.com/edgefocus/efp/pull/6209
- DEV-1509 — https://linear.app/edge-focus/issue/DEV-1509/rename-experimental-northpond-fund
- Project: [[wm-j523sq]]

## Log
- 2026-08-14T14:54Z [claude-code] Correction to the body above: the '## Next steps' section tells you to run 'taskmem chain wm-8w4ntq' — that id does not exist. I wrote the body before the CLI assigned an id. The correct command is 'taskmem chain wm-4sxy5d --oneline'.
- 2026-08-14T20:10Z [claude-code] Wrote up the whole NorthPond/Oliv picture at ~/notes/northpond/ (README + feeds/columns, standardized column mapping, EDGEX deal state, findings; the 2026-08-12 feeds doc is archived there). Verified 2026-08-15: PR #6277 is OPEN, commits 64597180ff and 131a4e85b0 are NOT ancestors of origin/master - so prod still runs the NORTHPOND_EDGEX_PURCHASE_START='2026-08-01' date hack and ingests no Nelnet feeds. Two new findings filed: wm-tvqc6y (no 'recovery' DESCRIPTION on the Nelnet transaction leg) and wm-4tjdus (purchase file v1 drops application_uuid).
