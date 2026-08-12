---
id: wm-hecgua
type: task
title: Commit or salvage the untracked OpenRoad silver-vs-datastore docs + create openroad_verified.py
status: next
priority: high
due: 2026-08-12
links: [parent:wm-su6q4d, relates:wm-6zdqhy]
created: 2026-08-12T12:18:40Z
updated: 2026-08-12T12:53:29Z
source: claude-code
effort: <1h
---

Found 2026-08-12 while searching for "OpenRoad verified differences".

WHERE IT LIVES (single copy, at risk):
`~/repos/efp/docs/openroad-silver-vs-datastore/` on dpx — **untracked** (`??` in
git status), never committed to any branch, absent from git history on all
remotes. Checkout is `~/repos/efp` @ branch
`abhishek/dev-1393-fixes-in-openroad-positions` (128 commits behind master).
Files (2026-07-24): `README.md` (75 lines), `positions-mismatches-2026-07-01.md`
(64 lines) — a 16-row consolidated mismatch table from
`compare_datastore_positions --platform openroad --date 2026-07-01`
(35 loans, 95/125 cols matching pre-fix, 99/125 after DEV-1393).

Modeled on the committed `docs/northpond-silver-vs-datastore/` (see [[wm-6zdqhy]]).

THERE IS NO `openroad_verified.py`. master's
`edgefocus/transformations/silver/comparison/` has happymoney, innovate,
marlette, northpond, sofi, upgrade, upstart verified files; `verified_differences.py`
contains zero openroad references.

OPEN DECISIONS RECORDED IN THE DOC:
1. #2/#3 credit_score / VANTAGE4 (17/35 loans NULL in silver) — the real
   TransUnion score is not in `bronze.api_events` (only 159 of 301,231 events
   have a non-JSON-null vantage4); legacy reads flat model_requests/model_responses
   statement files never ingested to bronze. Decide: build that ingestion
   (relates [[wm-bpmxnb]]) or register as a data gap.
2. #12 remaining_term/remaining_term_over_2/terms_seasoned (16/35, ~14mo avg
   divergence) — silver's actuarial npf.nper calc vs legacy Foursight's simple
   maturity_date−as_of_date, current-status-only. Explicitly left "needs a call
   from Abhishek" and out of scope for DEV-1393.
3. #13 mgr_mark_dq_bucket (5/35), #14 as_of_month (18/35, looks like comparison-tool
   staleness not silver), #16 interest_at_purchase (1/35) — untraced, low value.
4. Register #6 pool_id, #7 zip_code, #8 apr_at_purchase, #10 pti, #11 the 16-loan
   offer-join family, #15 is_joint (+ #2/#3 if deferred) in a new
   `openroad_verified.py` so comparison runs stop flagging them.

NEXT: back the folder up / commit it somewhere durable before that stale checkout
gets cleaned or reset, then land it alongside `openroad_verified.py`.

## Log
- 2026-08-12T12:21Z [claude-code] Provenance evidence assembled 2026-08-12 (proof the doc predates today). (1) dpx session transcript ~/.claude/projects/-home-abhishek/467f6ab1-466e-4f2f-a7e0-f55d0215ab0c.jsonl records the literal Write tool calls: README.md at 2026-07-07T16:57:43Z, positions-mismatches-2026-07-01.md at 2026-07-07T16:58:26Z, plus 3 Edits on 2026-07-08T16:56-16:57Z; 87 mentions across that session. (2) Source data it was derived from still on disk: /tmp/claude-2053/-home-abhishek/467f6ab1-.../scratchpad/openroad_compare_aligned.txt, 18036 bytes, dated 2026-07-07 16:47 — 10 min before the doc was written. (3) 4 other dpx transcripts reference the folder: b6fbfb79 (2026-07-08), 42b66000 (2026-07-13), ec4fd968 (2026-07-13 to 07-15), a6354544 (2026-07-16). (4) STRONGEST PUBLIC PROOF: PR #5807 'DEV-1393: Fixes in OpenRoad Positions', opened 2026-07-08T17:29:24Z, MERGED 2026-07-09T18:12:46Z — its body restates the doc's findings verbatim including the exact '95/125 to 99/125 perfect column matches' figure, 32 min after the last doc edit. (5) taskmem wm-6zdqhy already cited the sibling openroad doc as untracked. CAVEAT: both files' mtime is 2026-07-24 16:49:22.923070599 — IDENTICAL to the nanosecond across both, which indicates a bulk copy/restore into place on 07-24, not an individual edit; no surviving transcript covers 07-24 (dpx transcripts stop at 2026-07-20) and no second copy exists anywhere on the box. So mtime understates age by ~17 days; the transcript+PR chain is the real dating evidence.
- 2026-08-12T12:27Z [claude-code] FRANK IS ASKING — this is now blocking a reply. 2026-08-12T00:45:35Z Frank commented on Scott Morgan's Linear doc 'Datastore Retirement — Open Questions & Linear Coverage Gaps (2026-08-07)' (initiative: Deprecate Datastores by EOY 2026), inline on Q6, anchored to the quoted text 'prosper, anchored, openroad, lc': 'lc is not yet ingested. But for prosper, anchored and openroad, @sanjali and @abhishek is this right? We don't have the verified-differences file? Was that a miss?' Q6 as written by Scott: 'Positions parity: verified-differences files exist for 7 platforms but not prosper, anchored, openroad, lc. Was prosper's validation recorded elsewhere (DEV-822/DEV-993), or is this a real gap?' CONFIRMED on origin/master: comparison/ has happymoney, innovate, marlette, northpond, sofi, upgrade, upstart _verified.py — no openroad, prosper, or anchored; verified_differences.py has 0 openroad/prosper/anchored references. So Frank is factually right about the missing FILE. But for OpenRoad the validation itself was NOT missed: full-history compare_daily_summary over 1,079 dates, the 16-row mismatch table, 4 issues fixed and merged in PR #5807 (2026-07-09). Only the registration file was never written. Prosper/anchored are Sanjali's to answer, not mine. Doc URL: https://linear.app/edge-focus/document/datastore-retirement-open-questions-and-linear-coverage-gaps-2026-08-ed6197316dcf
- 2026-08-12T12:43Z [claude-code] DEFINITIVE: openroad_verified.py NEVER existed. Deep re-check 2026-08-12 with no depth limit: 'find ~ -name "*openroad_verified*"' returns nothing anywhere on dpx; all 16 checkouts carry only happymoney/innovate/marlette/northpond/sofi/upgrade/upstart _verified.py; no git stash in any checkout; 'git log --all --diff-filter=A -- *openroad_verified*' and 'log --all -S openroad_verified' are both empty in repos, repos-2 and repos-3. The single mention of the string anywhere is inside session 467f6ab1 (which wrote the docs) and the doc itself, where it appears as a PLANNED artifact ('candidate for openroad_verified.py' in the legend; Status item 6 'Register #6,#7,#8,#10,#11,#15 ... in a new openroad_verified.py'). So the recollection is of the plan, not the file. PUBLIC PROOF-OF-AWARENESS LINKS (all created by Abhishek on 2026-07-08, all linkable): DEV-1393 'Fixes in OpenRoad Positions' (created 2026-07-08T14:00Z, Done 07-09) — description enumerates the three mismatch families incl. the credit_score gap; DEV-1396 'Ingest OpenRoad model_requests/model_responses statement files for real credit score data' (created 2026-07-08T20:28Z, still open, stateHistory shows Todo until 2026-08-10 then moved to Backlog) — this IS the known-difference deliberately deferred, with Linear's own audit trail; DEV-1350 'Validate positions' (OpenRoad Data Ingestion project, milestone 'Validate positions', Done 2026-07-09); PR #5807 merged 2026-07-09. Supporting: DEV-1502 (Sanjali, 2026-07-31) 'silver.positions ZIP_CODE width is inconsistent across platforms (5-digit vs 3-digit)' = mismatch #7 escalated cross-platform by someone else, so the by-design diffs were known beyond just me.
- 2026-08-12T12:53Z [claude-code] DASHBOARD FOUND 2026-08-12 — the OpenRoad equivalent of the NorthPond comparison board exists, same 'done but last step never landed' pattern. (1) CANONICAL: uid openroad-sfvsds-fullhist, 'OpenRoad: SF vs Datastore — Full History Analysis', folder Abhishek, created 2026-07-03T19:23Z, still version 1, 52 panels — 11 metric families (loan universe, purchase metrics, daily position metrics, manager marks, origination/model scores, borrower metrics, charge-off, ITD cashflows, hardship/bankruptcy, geography, time periods, identifiers), each a text panel of root-cause annotations + a mismatch-%% timeseries over the full history. URL https://grafana.edgefocuspartners.com/d/openroad-sfvsds-fullhist/ (2) UPDATED DRAFT: uid 836a762d-1a37-4d62-a694-5e33367b19dd, same title + '(updated draft)', folder 'Testing Dashboards', tag openroad-dashboard-update-draft, version 5, updated 2026-07-08T20:39Z — i.e. right after PR #5807 went up. Its annotations carry the post-fix state ('IRR — fixed (DEV-1393)', 'ANL — fixed in code, pending prod deploy') whereas v1 still says 'Follow-up: wire OpenRoad predicted_cashflows -> positions ANL/IRR'. The draft was never promoted back into the Abhishek folder. CAUTION when sharing: linking the canonical board shows Frank the PRE-fix annotations, which reads worse than reality — promote the draft first or link the draft. Neither dashboard is codebase-pinned (no JSON in the repo, no grafana/ dir), so promotion is a Grafana-side move, not a PR.
