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
updated: 2026-07-28T11:16:33Z
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

## Log
- 2026-07-28T10:49Z [claude-code] CORRECTION to the 2026-07-28 entry: northpond_verified.py is NOT missing — it was WRITTEN and then PULLED from the PR. Recovered today.

- Added in commit f268acda2 'DEV-1291: Register Northpond ANL/IRR/EF_SCORE as verified positions differences' (79 lines, 5 columns: anl, irr, anl_band, irr_band, ef_score; verified_by=abhishek, verified_date=2026-06-20) on branch abhishek/dev-1291-address-review-comments.
- Removed in ec288e153 'Remove northpond verified differences files from PR' (2026-06-22 19:30) with the body: 'Will be added in a separate PR once the datastore comparison baseline has been established post-merge.' Self-initiated deferral, not a reviewer ask. PR #5624 merged without it.
- The commit also added a 6-line northpond_verified import block to _load_platform_verifications() in verified_differences.py — that half must come back too or registration never fires.
- Recover: git checkout f268acda2 -- edgefocus/transformations/silver/comparison/northpond_verified.py (done today into dpx ~/repos/efp working tree, unstaged).
- The baseline that deferral was waiting on IS now established (full-history comparison, board 98ba2ef7 annotated per family), so the follow-up PR is due.

FRANK COMMENT — searched exhaustively, no second ask exists. Swept every human comment on PRs 5504, 5551, 5579, 5584, 5610, 5624, 5704, 5749, 5874, 5876, 5917, 5925, 5936, 5965, 5967, 5993 (issue comments + review comments incl. outdated + review bodies). Frank's ONLY substantive NorthPond ask is the #5504 approval review of 2026-06-16 (comparison stats/graphs, pointing at Eshan's Upgrade board). He never commented on northpond_verified.py — it was removed 2026-06-22 19:30, his #5624-era review landed 2026-06-23 02:33. On #5624 he wrote only 'Ok great thanks for the updated int tests and additional changes. Looks good!'

positions-validation.md updated with the recovery instructions and a candidate list of columns to add beyond the original 5 (is_joint, zip_code, pool_id, mgr_mark_dq_bucket, as_of_month, terminal-NULLing group, legacy one-day-offset group). Deliberately EXCLUDES the 8 issuance-derived columns — already 0% since 2024-11-21, suppressing them would mask a future regression.
- 2026-07-28T11:16Z [claude-code] SHIPPED 2026-07-28: PR #6058 https://github.com/edgefocus/efp/pull/6058 — 'northpond: register verified positions differences + validation docs', branch abhishek/northpond-verified-differences off latest master (dfcf0695c), 9 files / +875.

Built in a NEW git worktree at dpx ~/claude-ws/np-verified (created via 'git worktree add' from ~/repos-2/efp) specifically so none of the three existing checkouts were disturbed — ~/repos/efp has ~20 untracked/modified files on the openroad branch, ~/repos-3/efp is on the ramp branch, ~/tmp/np-pr is another copy on dev-1412. All left untouched.

Contents:
- northpond_verified.py: 21 columns registered (5 prediction + is_joint/zip_code + pool_id/mgr_mark_dq_bucket/as_of_month + 4 terminal-NULLing + 6 one-day-offset + itd_payment_transaction_received). Expanded from the original 5 using the Grafana board 98ba2ef7 annotations.
- verified_differences.py: 6-line import block in _load_platform_verifications(). NOTE master already had upstart_verified registered.
- docs/northpond-silver-vs-datastore/ (7 files) now COMMITTED — previously untracked for ~6 weeks.

Verified before commit: get_verified_differences('northpond')=21 unique, all fields populated; other platforms unchanged (sofi 38, upstart 24, marlette 58, happymoney 10, upgrade 95); ruff check + format clean; mypy clean. Ran with ~/repos-2/efp/.venv (the worktree has no venv of its own).

GOTCHA worth remembering: writing python via an ssh heredoc silently ate two dollar amounts ('$0-4k' -> '/bin/zsh-4k' via $0, '$4.29' -> '.29' via $4). Caught by a SyntaxWarning on import. For anything with $ in it, scp a file instead of heredoc-ing it.

STILL OPEN — needs Abhishek's decision, called out explicitly in the PR body: purchase_year/purchase_quarter semantics (silver = efhyf TRANSFER_DATE, datastore = original acquisition; purchase_date itself is 0% mismatch). Deliberately NOT registered. Also not registered: the 8 issuance-derived columns (0% since 2024-11-21) and the >99%-match one-off blips.
