---
id: wm-e9bhr2
type: task
title: Keep the ~/notes NorthPond knowledge base current as EDGEX moves
status: next
priority: p2
size: s
tags: [northpond, notes]
links: [parent:wm-j523sq]
created: 2026-08-17T11:18:19Z
updated: 2026-08-31T21:10:51Z
source: claude-code
---

Home: `~/notes` on the Mac (agent protocol in `~/notes/AGENTS.md`).
Mirror: `dp:~/notes` via `~/notes/bin/sync-to-dpx.sh` — push after every edit.

NorthPond content was verified 2026-08-15, so parts are already known-stale.
All of this is listed in `notes/areas/efp/platforms/northpond/meta.md`:

1. **PR #6277 merge** [[wm-g8p2m2]] — when it lands, DELETE the prod-vs-branch
   split at the top of `platforms/northpond/README.md` and the "describes PR
   #6277" caveats in `standardized-mapping.md`. Grep the folder for 6277.
   Remove them, don't annotate.
2. **The 2026-08-17 Oliv cutover** [[wm-3vkbn9]] — everything in
   `feeds-and-columns.md` about Nelnet arrival, naming and cadence describes the
   pre-cutover state.
3. **Answers to the open questions** in meta.md each retire a finding when they
   arrive: INV103 sold-vs-earmarked [[wm-uxwcxn]], ANL gross-vs-net
   [[wm-v7apt2]], EDGEX purchase categories [[wm-abqg3u]].

Standing rule, now in `~/.claude/CLAUDE.md` and `dp:~/CLAUDE.md`: after work in a
platform, refresh what you touched and stamp that platform's `meta.md` in the
same edit.

## Log
- 2026-08-24T21:08Z [claude-code] 2026-08-25: added finding 11 to ~/notes/areas/efp/platforms/northpond/findings.md and stamped meta.md in the same edit (freshness row, known-stale item 4, provenance, change log). Covers NorthPond's two bureau generations behind the single northpond_loan_fl gateway channel, the nested-vs-flat application_uuid (request vs response) that caused the [[wm-zy97pd]] mis-diagnosis, the _credit_pull_success semantics, and the TurndownPrep pin-vs-NORTHPOND_MAP collision. Also corrected the README index, which said nine findings with ten present. api_events facts are prod-true; the DEV-1498 half is explicitly marked as an unpushed branch.
- 2026-08-31T20:16Z [claude-code] 2026-09-01: history pass. Added four 'why' files to ~/notes/areas/efp/platforms/northpond/ — decisions.md (30 design decisions, each with the rejected alternative and what breaks if reversed), incidents.md (20 root-caused failures behind a symptom->cause index), nate-and-oliv.md (the counterparty record: agreed vocabulary, commitments kept/missed, what Oliv refused, what is unanswered both ways), timeline.md (six-phase build log + full PR ledger with states verified via gh). Reconstructed from the whole local Claude session corpus (119 transcripts, ~40 NorthPond-relevant read in full), not from prod — no Snowflake/S3/Slack query was run, and every dated number keeps the pass that originally measured it. Also closed point 1 of this item: #6324 merged 2026-08-18T19:03:49Z (confirmed via gh pr view), so the prod-vs-branch caveats were REMOVED from README.md, standardized-mapping.md, findings.md and edgex-deal-state.md rather than annotated. Registered the four-file shape in platforms/README.md and STRUCTURE.md; meta.md stamped in the same edit; synced to the dpx mirror.
- 2026-08-31T21:10Z [claude-code] 2026-09-01 (2/2): data pass, measured against PROD. Added data-quality.md (live census as of AS_OF_DATE 2026-08-31: book by fund, field coverage with the reason for every gap, attribution matrix, feed volumes/freshness, ranked quality register, 'numbers you must not quote naively'), capabilities.md (can / can-with-caveat / cannot, each 'cannot' with what would unlock it) and versions.md (every file type + version lineage, what is deliberately ignored AND still arriving, plans on both sides). Queries kept at dp:~/claude-ws/np-data-notes/np_census{,2,3}.py with output in census*.out — read-only, PROD, COMPUTE_WH_XS_DEV, fresh local clone with its own .env, no other checkout touched. Findings: (1) I1 is live and WIDER than reported — the wrong fund is stamped on silver.northpond_stmt_purchase_tapes too, 160 loans / $438,199 across the 08-24..08-31 as-of dates, and the 141 EDGEX loans with no PRINCIPAL_AT_PURCHASE overlap the mislabelled set 141/141; (2) I10 unchanged, Nelnet EFFDATE still starts 2026-07-28, no backfill has landed; (3) I12 still exactly 55 unscored loans, $124,697.95; (4) NEW I21 — the Nelnet transaction-type filter is a silent allow-list and already dropped an undocumented ADJ-PAYMENT type; (5) the pre-cutover Nelnet formats (VELOCITY_SERVICING_DF2 with plaintext SSN/DOB/bank, and the V_Transaction xlsx) are STILL landing daily in efp-raw alongside the new ones — relevant to wm-8dy9jr; (6) good news: zero dark loans now (issuance 1,470 = positions 1,470 both directions) where 2026-08-12 had 364, and zero duplicate keys anywhere. meta.md stamped in the same edit; the three-file data shape registered in platforms/README.md and STRUCTURE.md; synced to the dpx mirror.
