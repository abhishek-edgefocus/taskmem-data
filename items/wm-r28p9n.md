---
id: wm-r28p9n
type: task
title: Raise sshd MaxSessions on dpx to prevent VSCode Remote-SSH channel saturation
status: dropped
tags: [dpx, infra]
created: 2026-07-14T16:09:11Z
updated: 2026-07-14T16:39:53Z
source: claude-code
---

2026-07-14: Claude Code (and all remote extensions) stopped loading in VSCode on dpx. Root cause: ~/.ssh/config ControlMaster multiplexing + sshd default MaxSessions=10 on dpx — the shared SSH connection's channel table saturated, so VSCode's extension-host socket took 13-139s to open and missed its 60s ready deadline. Fixed by killing the control master (ssh -O exit dp). Follow-up: set MaxSessions 64 in /etc/ssh/sshd_config on dpx (needs sudo) so this can't recur.

## Log
- 2026-07-14T16:33Z [claude-code] Server-side changes are out of Abhishek's scope on dpx (shared host). Prevention must be client-side: remove ControlMaster sharing for the dp host, or give VSCode its own SSH config. Quick recovery if it recurs: ssh -O exit dp, then Reload Window.
- 2026-07-14T16:39Z [claude-code] RESOLVED client-side instead: removed ControlMaster/ControlPath/ControlPersist from the dp host block in ~/.ssh/config so VSCode Remote-SSH gets a dedicated connection. Verified: exthost9 on dpx activated 10 extensions incl. Anthropic.claude-code at 2026-07-14 16:39 UTC. If slow-socket symptoms ever return, check for anything re-multiplexing ssh to dpx.
