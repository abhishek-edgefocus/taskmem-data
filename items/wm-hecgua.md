---
id: wm-hecgua
type: task
title: Commit or salvage the untracked OpenRoad silver-vs-datastore docs + create openroad_verified.py
status: next
priority: high
due: 2026-08-12
links: [parent:wm-su6q4d, relates:wm-6zdqhy]
created: 2026-08-12T12:18:40Z
updated: 2026-08-12T12:27:08Z
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
