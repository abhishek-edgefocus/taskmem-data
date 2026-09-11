---
id: wm-4tkx4g
type: bug
title: taskmem new prints the full item JSON, so $(taskmem new …) captured as an id produces garbage downstream
status: inbox
tags: [taskmem-bug]
created: 2026-09-11T14:26:45Z
updated: 2026-09-11T14:26:45Z
source: claude-code
label: taskmem new prints the full
---

Ran `ID=$(taskmem new task "…" …)` then `taskmem log $ID …`, `taskmem link $ID …`, and used `$ID` inside a second item's body and `links=follows:$ID`. Expected: `$ID` = `wm-uwncjv`. Got: the entire JSON record (frontmatter + body), so `log`/`link` failed with "invalid id: {…}" and the second item (wm-ux3df4) was created with a multi-KB JSON blob in its body and ~40 garbage `links` entries; had to `set --body` + `links=` to repair it.

Fix options: a `--quiet` / `--id` flag on `new` that prints only the id; or document `taskmem new … | jq -r .id` in AGENTS.md next to the session-lifecycle examples. The repair itself worked fine via `set`.


## Environment
- taskmem: 67d432e
- reported by: claude-code
- host: ip-192-168-1-3.ap-south-1.compute.internal
- when: 2026-09-11T14:26:45Z
