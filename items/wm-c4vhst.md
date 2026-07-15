---
id: wm-c4vhst
type: task
title: Create private GitHub repo (personal profile) and push taskmem infra branch
status: done
priority: p2
due: 2026-07-17
tags: [taskmem]
links: [relates:wm-kpyq3c]
created: 2026-07-15T13:53:45Z
updated: 2026-07-15T17:38:35Z
source: claude-code
---

Goal: private repo github.com/<personal-user>/taskmem containing ONLY infrastructure for now — Abhishek explicitly excluded task content at this stage. A task-free orphan branch 'infra' (1 commit, 12 files: bin/, prompts/, docs, install.sh — no items/, archive/, DASHBOARD.md, no history) is already built locally in ~/taskmem.

IMPORTANT: do NOT 'git remote add' in ~/taskmem yet — the 15-min autosync cron would push local main (which contains all tasks) on its next tick. Push the infra branch remoteless-ly instead (step 3).

## Next steps
1. Register this machine's SSH key with GitHub (personal account): https://github.com/settings/ssh/new — paste ~/.ssh/id_rsa.pub
2. Create the empty PRIVATE repo under the personal profile (not the org): https://github.com/new — name: taskmem, Private, no README.
3. Push without configuring a remote:  git -C ~/taskmem push git@github.com:<user>/taskmem.git infra:main
4. Verify on github.com: private badge, 12 files, 1 commit, no items/.
5. LATER, when ready to include tasks: git -C ~/taskmem remote add origin git@github.com:<user>/taskmem.git && git push -f origin main && tm sync  (force-push replaces the infra-only main with full history; autosync takes over from there).

## Links
- Infra branch (local): ~/taskmem, branch 'infra'
- Related deferred restructure: wm-jpxt8v (brain monorepo — repo can be renamed on GitHub later without breaking anything)

## Log
- 2026-07-15T15:43Z [claude-code] infra branch built and verified task-free (12 files, 1 commit); blocked on user: SSH key registration + repo creation (no gh/token/brew on this machine)
- 2026-07-15T17:38Z [claude-code] DONE: private repo created at github.com/abhishek-edgefocus/taskmem (personal account, verified private:true), infra branch pushed as main — 12 infra files, zero task content, no history. gh CLI installed via direct binary + device-flow auth; git credential helper configured. No remote configured locally, so autosync cannot push tasks.
