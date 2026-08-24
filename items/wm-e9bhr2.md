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
updated: 2026-08-24T21:08:32Z
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
