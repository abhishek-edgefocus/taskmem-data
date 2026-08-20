---
id: wm-rn43ak
type: task
title: Re-login Claude Code on dpx and turn Remote Control on
status: blocked
size: ~15m
tags: [dpx]
created: 2026-08-20T18:42:12Z
updated: 2026-08-20T18:42:17Z
source: claude-code
---

dpx `~/.claude/.credentials.json` is dead: `claudeAiOauth.expiresAt = 0` and `refreshTokenExpiresAt` lapsed 2026-08-17.

A tmux session `claude-remote` is running on dpx under abhishek only (started `~/.local/bin/claude --remote-control dpx`, cwd `~`), but `/status` reports `Login: Expired` and `Session kind: interactive` — Remote Control never attached.

To finish: `ssh dp` → `tmux attach -t claude-remote` → `/login` → `/remote-control`.

Blocked on interactive OAuth; an agent cannot complete it.
