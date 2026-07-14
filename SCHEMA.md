# SCHEMA — the stable data contract

This file defines the data model and CLI semantics. It is the **stable layer**:
agents, models, and prompts may change freely, but changes to this file are rare
and deliberate. Any AI agent that can run a shell command and follow this
document is a full citizen of the system.

## Anatomy of a work item

One markdown file per item at `items/<id>.md`:

```markdown
---
id: wm-k3f9a2
type: followup
title: Ask Rahul about the pricing API timeline
status: open
priority: p2
due: 2026-07-16
people: [Rahul]
tags: [pricing]
links: [relates:wm-8d2c1f]
created: 2026-07-14T09:12:33Z
updated: 2026-07-14T09:12:33Z
source: claude-code
---

Came up while reviewing the pricing integration. Rahul owns the upstream
API; we need his timeline before scheduling our work.

## Log
- 2026-07-14T09:12Z [claude-code] created; inferred from "need to ask Rahul"
```

Frontmatter is deliberately a **flat YAML subset**: string scalars and flat
lists of strings only (`key: value`, `key: [a, b]`). No nesting, no multiline
values — anything richer belongs in the markdown body. List values must not
contain commas. Files remain valid YAML for other tooling (Obsidian, pandoc…).

## Reserved fields

| Field    | Written by | Semantics |
|----------|-----------|-----------|
| id       | wm        | Immutable. `wm-` + 6 chars. Filename = `<id>.md`. |
| type     | agents    | Open vocabulary; see below. |
| title    | agents    | Short, specific, imperative where possible. |
| status   | agents    | Open vocabulary; see below. Default `open`. |
| priority | agents    | `p0` (drop everything) … `p3` (someday). Optional. |
| due      | agents    | `YYYY-MM-DD`, local-date semantics. Only if a real date exists. Validated on write; `today+N` accepted. |
| people   | agents    | Humans involved (first names or handles, consistently). |
| tags     | agents    | Lowercase, hyphenated. Use one tag per project/area. |
| links    | wm/agents | Directed edges `rel:target-id` (see Links). |
| created  | wm        | Immutable UTC timestamp. |
| updated  | wm        | UTC timestamp, touched on every mutation. |
| source   | agents    | Where the item came from (agent name, meeting, thread…). |

**The schema is open.** Any other `key: value` is legal and preserved —
adapters may add `github_pr: 142`, `channel: #launch`, `msg_ts: …` without any
infrastructure change. Namespace adapter-owned fields by prefix.

## Vocabularies (conventions, not constraints)

The infrastructure never validates these — consistency is an agent
responsibility. Extend them by editing this file.

- **type**: `task` `bug` `reminder` `followup` `research` `decision`
  `question` `idea` `note`
- **status**: `open` (ready) · `active` (in progress) · `blocked` (has a named
  blocker) · `waiting` (on a person/event; name it in `people`/body) · `done` ·
  `dropped` (deliberately abandoned — never delete, mark dropped and log why)
- **link rels** (read left-to-right, stored on the source item only):
  `blocks` · `parent` (source is parent of target) · `relates` ·
  `duplicate-of` · `follows` (source is a follow-up of target)
  Reverse direction is **derived at query time** (`wm links <id>` shows both
  directions; `wm find --where links~:<id>` finds inbound references).

## Body conventions

Free markdown. Two conventions: the body opens with enough context that a
fresh agent (or the human, months later) understands the item without the
originating conversation; and `## Log` is the **last** section — an
append-only trail written via `wm log` (`- <timestamp> [<agent>] message`).

## CLI contract

All output is JSON (JSONL for `find`/`search`) on stdout; errors are
`{"error": …}` on stderr with exit 1. Set `WM_AGENT=<name>` (or pass `--by`)
so mutations are attributed to you — in `## Log` lines and as the git author.
`WM_DIR` overrides the memory location (default `~/workmem`).

| Command | Purpose |
|---------|---------|
| `wm new <type> <title> [k=v …] [--body -\|text]` | create; prints the item with `id` |
| `wm get <id…> [--raw]` | read (JSON or raw markdown) |
| `wm set <id> k=v k+=v k-=v [--body …]` | update fields (`k=` clears; `+=`/`-=` edit lists) |
| `wm log <id> <message>` | append an attributed line to `## Log` |
| `wm link/unlink <id> <rel> <id>` | manage directed edges (validates targets) |
| `wm links <id>` | outbound + inbound edges |
| `wm find [--where EXPR]… [--sort k:desc,k2] [--limit N] [--offset N] [--fields a,b] [--full] [--count] [--oneline]` | generic query |
| `wm search <text> [--limit N]` | full-text, all-tokens-match, scored |
| `wm history <id> [--diff]` | git history of one item |
| `wm rm <id…>` | hard delete (prefer `status=dropped`) |
| `wm notify <title> <message>` | OS notification |
| `wm sync` | commit; pull --rebase + push if a remote exists |

### Query grammar

`--where "field OP value"`, repeated flags AND together.

- Ops: `=` `!=` (comma = set membership: `type=task,bug`), `~` `!~`
  (case-insensitive substring; on lists: any element), `<` `<=` `>` `>=`
  (numeric if both sides are numbers, else string — ISO dates compare
  correctly, and a date compares correctly against a timestamp).
- `null` matches absent/empty: `due!=null`, `priority=null`.
- Date sugar: `today`, `today+7`, `today-14`, `now` expand before comparing.
- On list fields, `=` means membership: `tags=pricing`, `people=Rahul`.
- Relationship queries need no special syntax — links are just a field:
  `links~blocks:` (has outbound blocks), `links~:wm-x` (any edge to wm-x).

Composition examples (this is how "specialized" queries are expressed):

```bash
wm find --where "status!=done,dropped" --where "due<=today" --sort due     # due/overdue
wm find --where status=waiting --where people=Rahul                        # waiting on Rahul
wm find --where "status!=done,dropped" --where "updated<today-14"          # stale
wm find --where "links~blocks:" --where "status!=done,dropped"             # blocking items
wm find --where type=decision --sort created:desc --limit 10               # recent decisions
```

## History

Every mutation auto-commits to git with the acting agent as author, so
`wm history` and `git log` reconstruct who changed what, when, and why —
without any bespoke history code. `WM_NO_COMMIT=1` batches mutations into a
later `wm sync` commit.
