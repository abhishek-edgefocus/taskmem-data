---
id: wm-rn43ak
type: task
title: Re-login Claude Code on dpx and turn Remote Control on
status: blocked
size: ~15m
tags: [dpx]
created: 2026-08-20T18:42:12Z
updated: 2026-08-20T19:25:02Z
source: claude-code
---

dpx `~/.claude/.credentials.json` is dead: `claudeAiOauth.expiresAt = 0` and `refreshTokenExpiresAt` lapsed 2026-08-17.

A tmux session `claude-remote` is running on dpx under abhishek only (started `~/.local/bin/claude --remote-control dpx`, cwd `~`), but `/status` reports `Login: Expired` and `Session kind: interactive` — Remote Control never attached.

To finish: `ssh dp` → `tmux attach -t claude-remote` → `/login` → `/remote-control`.

Blocked on interactive OAuth; an agent cannot complete it.

## Log
- 2026-08-20T19:15Z [claude-code] Confirmed empirically on dpx: ~/.claude.json still shows hasTrustDialogAccepted=false for /home/abhishek after the trust dialog was accepted, so home-dir trust never persists — every launch prompts. ~ is also not a git repo, so --spawn worktree is unavailable; use the default same-dir. He wants cwd ~ (not a project dir), so the target command is: tmux new -d -s cc-remote -c ~ '~/.local/bin/claude remote-control --name dpx' then tmux send-keys -t cc-remote Enter to clear the trust prompt. Still blocked on /login.
- 2026-08-20T19:25Z [claude-code] Ordering gotcha found: 'claude remote-control' (server mode) checks eligibility BEFORE anything else and exits 1 with 'You must be logged in to use Remote Control' while the token is expired. Because tmux new-session dies when its command exits, the tmux session vanishes instantly — which is why his cc-remote was not there. So /login CANNOT be done inside server mode; it has to happen in a plain interactive claude session first, then start the server.
