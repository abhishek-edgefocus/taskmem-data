---
id: wm-7cmpve
type: project
title: Focus agent: keep Abhishek on one ranked track across parallel tabs
status: active
tags: [meta, agents]
created: 2026-08-24T13:47:48Z
updated: 2026-08-24T13:47:48Z
source: focus-agent
label: focus agent role
---

Fifth coordinating tab, alongside session-manager, pr-board, session-critic and the Linear agent. Those four report state; this one decides what he should be working on and nudges him when a tab has drifted onto something lower-value.

Encoded as the `focus` skill at ~/.claude/skills/focus/SKILL.md, with the role memory at ~/.claude/projects/-Users-abhishek/memory/focus-agent-role.md. The skill carries the priority ladder (live exposure -> EDGEX 2026-1NN deal readiness -> a named person waiting on him for <=15m -> the NEXT step of an active chain -> platform work -> AI-spend -> meta-work), the four drift patterns he repeats (duplicate tabs, findings that never become actions, circular self-blocks, verification rabbit holes), and the rule that the top of the track gets verified against S3/Snowflake/gh before he spends a day on it.

Set up 2026-08-24 at his request: "keep me on track when I am digressing... if I'm focusing on less important things, highlight me that."
