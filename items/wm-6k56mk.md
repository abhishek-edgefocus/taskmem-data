---
id: wm-6k56mk
type: task
title: Disable the dpx ~/tasks crontab (unattended claude runs + automated DMs, against policy)
status: next
priority: p1
due: 2026-07-16
people: [Abhishek]
tags: [taskmem]
links: [relates:wm-c4vhst]
created: 2026-07-15T15:08:25Z
updated: 2026-07-15T17:48:28Z
source: intake-review
---

The old task system on dpx (~/tasks) still has a live crontab running
unattended claude (bin/agent-brief daily/weekly) and sending automated
Slack DMs — it sent a stale "Morning brief — Wed Jul 15" self-DM today
referencing old dpx #ids. That violates the no-unattended-claude-runs
policy, and it risks split-brain: all 13 live items + 4 projects were
imported into taskmem on 2026-07-15 (each carries source "dpx-tasks #N"),
so taskmem is canonical now. The dpx CLI itself crashes on the box's
default python3 (uses 3.10+ syntax), so the old store isn't mutating —
only its cron agents are still alive. dpx is a shared server that agents
must never modify; this is a human-only task.

## Next steps
1. ssh dp
2. crontab -e → delete the block between "# >>> task-system >>>" and
   "# <<< task-system <<<" (that kills agent-brief daily/weekly + dash).
3. Optional: mv ~/tasks ~/tasks.archived — keeps git history, makes the
   deprecation obvious.
4. Optional: remove the old SessionStart/SubagentStart hooks pointing at
   ~/tasks/bin/session-context from dpx ~/.claude/settings.json, and the
   ~/.local/bin/task symlink.
5. Follow-up: once the taskmem GitHub remote exists (wm-c4vhst), clone
   taskmem on dpx per README "Setup on a fresh machine" so dpx becomes a
   sync peer instead.

## Links
- Evidence: today's stale automated self-DM in Slack ("Morning brief — Wed Jul 15")
- Old system docs on dpx: ~/tasks/README.md, ~/tasks/PROTOCOL.md
- Blocked-on/related: wm-c4vhst (create taskmem GitHub remote)

## Log
- 2026-07-15T15:12Z [intake-review] upgraded to pickup-ready standard (context, next steps, links)
- 2026-07-15T15:16Z [claude-code] Planned for tonight (2026-07-15 evening block): human-only, doing first at ~21:00
- 2026-07-15T17:48Z [claude-code] GitHub remote of the old system (abhishek-edgefocus/tasks) deleted after verification: GH HEAD == dpx HEAD 423047b, single branch, all 18 items already imported into taskmem, projects.yaml -> project items. dpx ~/tasks folder still holds full history until archived (this item's remaining step). Note: dpx agent-brief's post-run 'git push origin' will now fail silently — harmless, and moot once the crontab is removed.
