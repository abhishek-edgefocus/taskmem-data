---
id: wm-njbe6v
type: bug
title: install.sh did not set WM_AGENT, so attribution silently fell back to 'unknown'
status: inbox
tags: [taskmem-bug]
created: 2026-07-20T15:58:31Z
updated: 2026-07-20T15:58:31Z
source: claude-code
label: install.sh did not set WM_AGENT
---

Found while setting up the second machine: settings.json had no env key, so every session relied on an agent remembering 'export WM_AGENT'. Fixed in c660c2f — filing so the class of problem (setup steps that depend on agent memory) is on record.

## Environment
- taskmem: ece9970
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-20T15:58:31Z
