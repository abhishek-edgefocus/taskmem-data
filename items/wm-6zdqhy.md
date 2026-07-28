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
updated: 2026-07-28T12:15:12Z
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
- 2026-07-28T11:30Z [claude-code] REVISED 2026-07-28 per Abhishek, PR #6058 amended + force-pushed (now 3 files / +410, was 9 files / +875):

1. DOC IS A DOCUMENT, NOT AN INDEX. Stripped every reference to PR state / review comments / commit history from the docs AND the PR body: Frank's #5504 quote and the 'closes the open ask' framing, the f268acda2/ec288e153/#5624 history note, the bare 'PR: <url>' + 'PR #5504 ported...' lines in the README, 'not added in PR #5504' in transactions_itd. Rule going forward: these docs describe the platform, they do not narrate tickets or review threads.

2. NO ACCOUNT_NAME / ACCOUNT_ID MISMATCH ANYWHERE. Removed the account_id row from the per-column table, the 'fund-aware account_id' clause from the DEV-1290 bullet, the 'Mismatch #1' annotation on the ACCOUNT_ID row in positions.md, row #1 + theme #5 + the decide-semantics bullet in the 2026-06-10 log, and the mention in the PR body. REASON: Abhishek had a prior discussion with Prasheet about possibly RENAMING the account names, so the mismatch is not settled and must not be written up as one. Neutral ACCOUNT_ID -> account_name mapping rows (transactions.md/transfers.md style) are fine; framing it as a mismatch/bug is not.

3. FOLDER STRUCTURE. Collapsed docs/northpond-silver-vs-datastore/ (7 files) into docs/northpond/reconciliation_ledger.md — one folder named after the platform, one document, matching docs/upstart/. Dropped as unnecessary: positions.md, transactions.md, transfers.md, transactions_itd.md (per-table column maps), README.md (legend + source->target map), positions-mismatches-2026-06-10.md (superseded first-pass log). NOT LOST — all 7 still sit untracked at dpx ~/repos/efp/docs/northpond-silver-vs-datastore/ if any are wanted back.

Preference to carry forward: he wants lean, self-contained platform docs — one folder per platform named for the platform, minimal files, no cross-references to tickets/PRs/review threads.
- 2026-07-28T11:33Z [claude-code] RENAMED 2026-07-28: docs/northpond/reconciliation_ledger.md -> docs/northpond/snowflake-datastore-comparison.md. PR #6058 amended + force-pushed, title now 'northpond: register verified positions differences + datastore comparison doc'.

Abhishek questioned whether 'reconciliation ledger' was a real cross-platform convention. It is NOT — verified against origin/master:
- docs/upstart/reconciliation_ledger.md is the ONLY file in the repo using that name (Kushagra's Upstart work). Nothing else.
- The other platform docs folder, docs/marlette/, uses plain kebab-case descriptive names: MARLETTE_CASHFLOWS.md, data-quality-issues.md, dedup-rationale.md.
- Marlette also has edgefocus/transformations/silver/comparison/key_differences_marlette.md.

His suspicion about underlying business terminology was CORRECT and this is the important bit: 'reconcile' already means something else entirely in efp. bin/reconcile/<platform>/<channel>.py is a separate established business process with per-channel scripts — including bin/reconcile/northpond/northpond_loan_fl.py. Calling a datastore-vs-Snowflake comparison doc a 'reconciliation ledger' would collide with that.

New name matches the actual tooling: compare_datastore_positions.py / compare_datastore_transactions.py / compare_datastore_cashflows.py in edgefocus/transformations/silver/comparison/. Also dropped the 'follows docs/upstart/reconciliation_ledger.md precedent' line from the PR body — the precedent that matters is upstart_verified.py, not the doc name.

RULE: don't copy a naming convention from a single platform's file without checking it is actually a convention and doesn't collide with existing domain vocabulary.
- 2026-07-28T11:54Z [claude-code] DASHBOARD REVIEW 2026-07-28 — board is stale and the substrate no longer supports one of the claims in PR #6058.

BOARD: Grafana 98ba2ef7 JSON last edited 2026-06-22T14:20Z by abhishek (version 9, created 2026-06-15). Its text-panel annotations are dated 'as of 2026-06-10' / '2026-06-15'. Nothing touched in 5+ weeks.

SUBSTRATE: DEV_ABHISHEK.GOLD.POSITIONS_COMPARISON_DAILY, PLATFORM='northpond'. 121 rows spanning 2026-03-21..2026-07-19, UPDATED_AT 2026-07-20T06:04. BUT only 28 of those 121 dates are real comparisons (COMMON_COUNT>0, 715 loans, EXTRA_IN_DATASTORE=0); the other 93 have COMMON_COUNT=0 and EXTRA_IN_DATASTORE=715, i.e. silver empty in the sandbox. Clean dates run 2026-06-16..2026-07-19 with holes at 07-13 and 07-16/17/18. Ties to wm-srzcyx (stale DEV_ABHISHEK).

=> CLAIM TO CORRECT in docs/northpond/snowflake-datastore-comparison.md AND the PR body: 'full-history column-by-column comparison ... zero datastore-only loans across the entire 2-year history'. That was true of the earlier full-history run the dashboard annotations were written from, but the current queryable substrate holds only 28 comparable dates in a ~5-week window. Either re-run full history or restate the evidence window honestly.

NEW DIFFERENCES not in the doc (all post-date the 06-10/06-15 annotations):
- INT_RATE_AT_PURCHASE 98.74% (706/715), first nonzero 2026-06-16. Already tracked as DEV-503 / PR #5704 / wm-gxykru but absent from the doc and from northpond_verified.py.
- IS_HOME_OWNER_AT_PURCHASE 52.03%, first nonzero 2026-06-16. Was item #15 in the old 2026-06-10 log ('SF richer') but dropped out of the current doc.
- MODEL_VERSION 100%, first nonzero 2026-07-19 — brand new, only on the very last date. Relates to DEV-1024 v1/v2 (PR #5925, wm-unb6pr).
- ITD_PAYMENT_PRINCIPAL_RECEIVED 3.22% and ITD_PAYMENT_INTEREST_RECEIVED 3.36%, both first nonzero 2026-06-18. The doc and the northpond_verified.py reason string for itd_payment_transaction_received BOTH assert these two 'match 100%' — now false.

CHANGED vs the doc:
- PRINCIPAL_BAND: doc says ~19%, actual 0.42%.
- SCHEDULED_PAYMENT_AMOUNT: registered in northpond_verified.py, but 0.00% on every clean date in the window — never mismatches. Registration is currently a no-op.
- REMAINING_TERM: doc 6 loans (0.84%) -> actual 0.42% (3 loans).
- BANKRUPTCY_FILED_DATE / IN_BANKRUPTCY: doc says 2 loans -> actual 0.42% (3 loans).
CONSISTENT: POOL_ID 56.64, AS_OF_MONTH 27.55, INTEREST_AT_PURCHASE 23.78, MGR_MARK_DQ_BUCKET 21.96, PURCHASE_QUARTER 16.78, TERMS_SEASONED 10.63, PURCHASE_YEAR 9.93, MARKUP 1.82, EXPOSURE/MARKUP_BAND 0.98, ANL/IRR/bands 75.24, EF_SCORE/ZIP_CODE/IS_JOINT 100.

Not reported on: ACCOUNT_ID (per standing instruction).

NOT YET ACTIONED — awaiting Abhishek's call on whether to amend PR #6058.
- 2026-07-28T12:15Z [claude-code] BOT REVIEW on PR #6058 — both findings VALID, plus a third I found while checking them. Nothing fixed yet.

1. ITD COLUMN NAME (flagged by BOTH sentry[bot] and cursor[bot], medium). VALID. compare_datastore_positions.py builds ColumnResult with column_name=old_col (line 578) = the DATASTORE column name, and COLUMN_MAPPING lines 169-174 map cum_payment_transaction_received -> ITD_PAYMENT_TRANSACTION_RECEIVED. So my entry column='itd_payment_transaction_received' never matches; must be 'cum_payment_transaction_received'. Precedent confirms: sofi_verified.py:75 and marlette_verified.py:304 both register cum_*. (upgrade_verified.py registers BOTH cum_* at 368-391 and itd_* at 853-880.)

2. MARKUP ROOT CAUSE (cursor[bot] only, medium). VALID. positions_utils.py:937 defines MARKUP = NULLIF(PRICE_AT_PURCHASE,0)/NULLIF(PRINCIPAL_AT_PURCHASE,0) — a pure ratio of two purchase-tape fields, and EXPOSURE = PRINCIPAL*MARKUP + ACCRUED_INTEREST (line 953). interest_at_purchase never enters MARKUP. If the datastore's price is its principal x markup, a one-day principal offset cancels in the ratio. So attributing markup/markup_band/exposure to the at-purchase one-day offset is WRONG in both my reason strings and the doc. NOTE the dashboard's own annotation ('DS markup calculation uses slightly different interest-at-purchase input for efhyf') is equally untraced — markup was never traced to code by anyone. Real root cause UNKNOWN; must not be suppressed under a fabricated cause.

3. FOUND WHILE VERIFYING — THE PR'S WHOLE PREMISE IS WRONG. compare_daily_summary.py, which writes gold.positions_comparison_daily (the Grafana board substrate), has ZERO references to verified differences — it emits raw mismatch % keyed by SNOWFLAKE column name (line 267: for sf_col in COLUMN_MAPPING.values()). The ONLY consumer of the Python registry is the CLI report compare_datastore_positions.py (the 'VERIFIED' tag + unverified_issues list). So registering northpond_verified.py does NOT make the board read clean.
   How boards actually do it: Eshan's Upgrade board (uid 0f070087) has a Grafana CONSTANT variable 'verified_cols' — a hand-maintained list of SNOWFLAKE column names — plus a 'show_mode' custom variable ('Only unverified'/'All'), and every panel wraps each column in CASE WHEN '${show_mode}'='All' OR 'COL' NOT IN (${verified_cols}) THEN COL END. Entirely dashboard-side, independent of the Python registry. The NorthPond board 98ba2ef7 has NEITHER variable (only 'database').
   => To make the NorthPond board read clean, someone must add show_mode + verified_cols to the dashboard JSON (Snowflake names), which is a separate change from this PR. The PR body, the doc opening, and the northpond_verified.py docstring all currently claim otherwise and need rewording.

Awaiting Abhishek's call on all three.
