---
id: wm-9f9dd5
type: task
title: Wire PagerDuty MCP server into Claude Code (user scope)
status: done
priority: p3
size: xs
tags: [mcp, tooling, pagerduty]
created: 2026-09-22T17:10:18Z
updated: 2026-09-22T17:10:25Z
source: claude-code
---

## Log
- 2026-09-22T17:10Z [claude-code] Hosted server https://mcp.pagerduty.com/mcp (self-hosted variant deprecated/archived). Registered at user scope in ~/.claude.json with header 'Authorization: Token token=...'; key mirrored at ~/.pagerduty-key (0600). Verified: /users/me HTTP 200 as Abhishek Doshi, MCP initialize HTTP 200 (server v3.3.1), tools/list returns 18 tools, unauthenticated control returns 401. 'claude mcp list' shows pagerduty Connected. Key was pasted into a Claude transcript, so rotate when convenient.
