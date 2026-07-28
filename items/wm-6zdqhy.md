---
id: wm-6zdqhy
type: task
title: Document validated NorthPond positions (Frank's ask on PR #5504)
status: open
priority: p2
size: s
people: [Frank]
tags: [northpond]
links: [parent:wm-j523sq]
created: 2026-07-28T10:38:32Z
updated: 2026-07-28T10:38:32Z
source: claude-code
---

Frank approved PR #5504 (DEV-1075) on 2026-06-16 but asked for the comparison evidence: 'these numbers were compared against datastores correct? Do you have any stats / graphs / numbers that show the comparison and what is off / spot on?' — pointing at Eshan's Upgrade board as the example. Never formally answered on the PR.

## What already exists (found 2026-07-28)
- Grafana board: 'Positions Comparison - NorthPond (Abhishek)' uid 98ba2ef7-1b1c-4954-bf5a-87bfd8664593 — 39 panels, fully annotated with per-family root-cause text panels (current to 2026-06-15, post DEV-1290/1291). This IS the evidence Frank asked for.
- Draft docs, UNTRACKED in git on dpx ~/repos/efp/docs/northpond-silver-vs-datastore/ (branch abhishek/dev-1393-fixes-in-openroad-positions): README.md, positions.md, transactions.md, transfers.md, transactions_itd.md, positions-mismatches-2026-06-10.md (24-row mismatch log from the manual 2026-06-10 comparison). An older, thinner copy of 4 of these also sits at dpx ~/docs/northpond-silver-vs-datastore/ (dated 2026-06-17).
- Sibling: docs/openroad-silver-vs-datastore/positions-mismatches-2026-07-01.md (also untracked).
- Written by dpx claude session d13ab919-1bd8-4c48-b88c-d451058830f6 (2026-06-24).

## Done 2026-07-28
Wrote dpx ~/repos/efp/docs/northpond-silver-vs-datastore/positions-validation.md — consolidates the dashboard annotations + the mismatch log into one current-state doc. Untracked, not committed, no PR.

## Precedent to follow
Upstart did exactly this and COMMITTED it: docs/upstart/reconciliation_ledger.md (PR #6040, commit 570b49b83). Same shape — per-column ledger, root cause, correct side, status.

## Next steps
1. Decide whether the folder gets committed (Upstart precedent says yes) and on which branch/PR.
2. Reply on PR #5504 linking the board + the doc, closing Frank's review thread.
3. Follow-up ticket: create northpond_verified.py. NorthPond has NO verified-differences file (sofi/marlette/happymoney/upgrade all do, at edgefocus/transformations/silver/comparison/*_verified.py), so every expected/convention/harness-artifact diff still shows as a live mismatch on the board.
4. Open decision: purchase_year/purchase_quarter semantics — silver reports the efhyf TRANSFER_DATE, datastore reports the original acquisition date. purchase_date itself is 0% mismatch. Pick one and register it.
