---
id: wm-p73beu
type: task
title: Finish Claude Code Remote Control setup on dpx (needs a claude.ai re-login)
status: open
created: 2026-08-20T10:04:24Z
updated: 2026-08-20T10:04:24Z
source: claude-code
---

Run Claude Code sessions on dpx and drive them from the Claude app (Remote Control), instead of holding an ssh tab open.

## State on dpx (checked 2026-08-20)
- Claude Code **2.1.211** installed, native: `~/.local/bin/claude` -> `~/.local/share/claude/versions/2.1.211`. On PATH in login shells only.
- `tmux 3.0a` and `screen` available.
- Egress OK: api.anthropic.com and claude.ai both reachable.
- `claude --remote-control [name]` flag exists in this build.
- Launcher installed: `~/bin/cc-remote [name] [dir]` — starts/attaches tmux session `cc-<name>` running `claude --remote-control <name>`.

## Blocker
A test session (`claude --remote-control dpx-test` under tmux) came up with **"Not logged in · Run /login"** and banner **"API Usage Billing"**, even though `claude auth status` reports `loggedIn: true`, `authMethod: claude.ai`, `subscriptionType: max`. The stored login (`~/.claude/.credentials.json`, last touched 2026-07-20) no longer satisfies Remote Control.

Abhishek has to do this himself — OAuth cannot be completed by an agent:
```
ssh dp
claude          # then /login   (headless: prints a URL, paste the code back)
```
Then `cc-remote dpx` and pick the session up in the Claude app.

## Notes
- Not an unattended run: the session idles until a message is sent from the app. Nothing cron-driven.
- Test tmux session was killed after the check; nothing left running on dpx.
