---
id: wm-3w59tw
type: bug
title: Cannot reference an item's own id inside the body you create it with — 'taskmem new' assigns the id only after the body is written
status: inbox
tags: [taskmem-bug]
created: 2026-08-14T14:54:23Z
updated: 2026-08-14T14:54:23Z
source: claude-code
label: Cannot reference an item's own
---

WHAT I WAS DOING: creating container items whose bodies say "run `taskmem chain <this-item>
--oneline`" — the single most useful line to put in a container's Next steps.

WHAT HAPPENS: `taskmem new <type> <title> --body -` reads the body on stdin and only then mints
the id, so at write time the id is unknowable. I guessed a placeholder twice in one session and
had to follow each `new` with a correction log line. A guessed id is worse than no id: it looks
like a real wikilink, resolves to nothing, and the reader has no way to tell.

WHAT I EXPECTED: some way to self-reference — a token the CLI substitutes at write time (`{{id}}`
or `@self`), or an option to mint the id first (`taskmem new --print-id` / a `--body` applied in a
second pass).

WORKAROUND I USED: create with the body, read the returned id, then `taskmem log <id> "correction:
the id in the body is wrong, it is <id>"`. That leaves a permanent correction line on a
brand-new item, which reads badly for something that was never a real mistake in the work.

Cheapest fix I can see: have `new` substitute a literal `{{id}}` (and maybe `{{ID}}`) in the body
after minting. Two lines, no schema change, and it makes container items self-documenting.

Filed per AGENTS.md — reporting the friction rather than working around it silently.


## Environment
- taskmem: 813294b
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-14T14:54:23Z
