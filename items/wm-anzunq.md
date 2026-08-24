---
id: wm-anzunq
type: task
title: Re-authorize Linear MCP — no Linear tools load in Claude Code sessions
status: next
priority: p2
size: xs
tags: [mcp, tooling]
links: [relates:wm-gxykru]
created: 2026-08-24T18:19:21Z
updated: 2026-08-24T18:19:25Z
source: claude-code
---

Linear MCP is registered twice against the same endpoint and neither yields tools.

STATE (verified 2026-08-24):
- 'claude.ai Linear' (claudeai scope) — `claude mcp list` reports "Connected", but ZERO Linear tools load into the session (ToolSearch '+linear' returns nothing). The green tick is transport-level only and is NOT evidence of a working grant.
- 'linear-server' (local scope, project /Users/abhishek) — '! Needs authentication'. Same URL https://mcp.linear.app/mcp. A duplicate.
- Abhishek attempted a reconnect on 2026-08-24; no change observable from an already-running session.

THIS RECURS — it is a lapsing OAuth grant, not a broken install:
- 2026-07-28T12:58Z: 'both Linear MCP servers are unauthenticated in this session' (see [[wm-gxykru]])
- 2026-07-28T13:19Z: 'MCP reconnected' — working again 21 min later, same day
- 2026-08-21: linear-agent successfully ran `mcp linear list_issues` (see [[wm-85vvgw]])
So it worked 3 days before breaking again. Expect periodic lapses; the value is in knowing the 60-second recovery, not a permanent fix.

KEY GOTCHA: MCP tool sets resolve once, at session start. Re-authorizing does NOT backfill tools into a session that already started — a fresh session is required to verify. Do not judge the fix from the tab where it broke.

FIX: (1) interactive session -> /mcp -> Linear -> Authenticate -> browser OAuth; (2) start a NEW session and confirm Linear tools actually load; (3) only once one path works, remove the duplicate with `claude mcp remove linear-server -s local`.

BLOCKS: the linear-agent tab cannot own ticket state without this.
