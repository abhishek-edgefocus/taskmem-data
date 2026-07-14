---
id: wm-r28p9n
type: task
title: Raise sshd MaxSessions on dpx to prevent VSCode Remote-SSH channel saturation
status: open
tags: [dpx, infra]
created: 2026-07-14T16:09:11Z
updated: 2026-07-14T16:09:11Z
source: claude-code
---

2026-07-14: Claude Code (and all remote extensions) stopped loading in VSCode on dpx. Root cause: ~/.ssh/config ControlMaster multiplexing + sshd default MaxSessions=10 on dpx — the shared SSH connection's channel table saturated, so VSCode's extension-host socket took 13-139s to open and missed its 60s ready deadline. Fixed by killing the control master (ssh -O exit dp). Follow-up: set MaxSessions 64 in /etc/ssh/sshd_config on dpx (needs sudo) so this can't recur.
