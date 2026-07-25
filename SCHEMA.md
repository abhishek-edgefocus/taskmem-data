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
| id       | taskmem        | Immutable. `wm-` + 6 chars. Filename = `<id>.md`. |
| type     | agents    | Open vocabulary; see below. |
| title    | agents    | Short, specific, imperative where possible. |
| label    | agents    | 3–5 keywords for glanceable naming — person, project, and/or core issue ("Abhijeet EDGEX reply", "NorthPond panels inventory"). Used as the heading of `delegate` prompts, so a delegated chat names itself something skimmable. No ids, no sentences. Optional; `delegate` falls back to truncating the title. |
| status   | agents    | Open vocabulary; see below. Default `open`. |
| priority | agents    | `p0` (drop everything) … `p3` (someday). Optional. |
| size     | agents    | Effort: `xs` <15m · `s` <1h · `m` 2–4h · `l` ~1d · `xl` multi-day. An `xl` must be decomposed into children. Optional. |
| due      | agents    | `YYYY-MM-DD`, local-date semantics — an external deadline. Only if a real date exists. Validated on write; `today+N` accepted. |
| scheduled | agents   | `YYYY-MM-DD` — the day the human plans to do it (distinct from `due`). Date-validated. |
| waiting_on | agents  | Who/what a `blocked`/`waiting` item is stuck on. |
| nudge    | agents    | `YYYY-MM-DD` — when to ping again about a blocked/waiting item. Date-validated. |
| people   | agents    | Humans involved (first names or handles, consistently). |
| tags     | agents    | Lowercase, hyphenated. Use one tag per project/area. |
| links    | taskmem/agents | Directed edges `rel:target-id` (see Links). |
| refs     | agents    | External jump links as `label=url` (issue, PR, dashboard, Slack thread). |
| created  | taskmem        | Immutable UTC timestamp. |
| updated  | taskmem        | UTC timestamp, touched on every mutation. |
| source   | agents    | Where the item came from (agent name, meeting, thread…). |

**The schema is open.** Any other `key: value` is legal and preserved —
adapters may add `github_pr: 142`, `channel: #launch`, `msg_ts: …` without any
infrastructure change. Namespace adapter-owned fields by prefix.

## Vocabularies (conventions, not constraints)

The infrastructure never validates these — consistency is an agent
responsibility. Extend them by editing this file.

- **type**: `task` `bug` `reminder` `followup` `research` `decision`
  `question` `idea` `note`
- **status**: `inbox` (captured by an agent, needs human triage) · `open`
  (triaged, ready) · `next` (chosen next action) · `active` (in progress) ·
  `blocked` / `waiting` (stuck — set `waiting_on`, usually `nudge`) ·
  `someday` (parked on purpose) · `done` · `dropped` (deliberately abandoned —
  never delete, mark dropped and log why)
- **link rels** (read left-to-right, stored on the source item only):
  `blocks` · `parent` (the target is the source's parent — children carry
  the edge) · `relates` ·
  `duplicate-of` · `follows` (source is a follow-up of target)
  · `blocks` is task-ordering — `A blocks B` means B can't start until A is
  done, and is what `taskmem chain` reads to order a milestone's steps and
  find the next actionable one (distinct from `status=waiting`, which is
  blocked on a person)
  Reverse direction is **derived at query time** (`taskmem links <id>` shows both
  directions; `taskmem find --where links~:<id>` finds inbound references).
- **projects are items**, not a registry file: `type=project`, goal as the
  first body line, `refs` for its dashboard/tracker links. Work items attach
  via `taskmem link <child> parent <project-id>`; children are found with
  `taskmem find --where "links~parent:<project-id>"`.
- **threads are lineages**, not a new construct: the first item captured
  from an origin (Slack thread, meeting, issue) is the thread anchor and
  carries the origin ref; later work attaches via `parent` (decomposition)
  or `follows` (successor work). `taskmem thread <id>` walks the transitive
  lineage in both directions (archived members included); `--oneline`
  renders it as a tree, `--all` traverses every rel.
- **`needs-reply` tag**: an @-mention or question addressed to the human
  that they haven't answered yet. Views (digest, dashboard, briefs) show
  these as "Replies you owe"; agents close them when the reply is observed.

## Generated views

`DASHBOARD.md` is rendered by `bin/dashboard` (and `bin/session-context`
feeds Claude Code session hooks). Both are deterministic renderings of the
generic queries above — never edit `DASHBOARD.md` by hand, regenerate it.

## Body conventions

Free markdown. Conventions: the body opens with enough context that a
fresh agent (or the human, months later) understands the item without the
originating conversation; `## Next steps` and `## Links` sections make it
pickup-ready (structure defined in AGENTS.md "Writing pickup-ready items");
and `## Log` is the **last** section — an append-only trail written via
`taskmem log` (`- <timestamp> [<agent>] message`). Append-only is enforced,
not merely conventional: `set --body` swaps the context above it and carries
the stored log through untouched, and a `## Log` passed inside `--body` is
ignored with a note on stderr. History can only grow, via `taskmem log`.

## CLI contract

All output is JSON (JSONL for `find`/`search`) on stdout; errors are
`{"error": …}` on stderr with exit 1. **The JSON is for programs that need
fields, not a hoop to jump through when reading.** To read an item you can
already name, read `items/<id>.md` directly or use `get --raw` (which accepts
several ids at once) — both give you the markdown as written. Reserve the CLI
for what it is actually needed for: querying across items, and every mutation
(so `updated`, `## Log`, git authorship and the commit all happen). Never
hand-edit an item file. Set `WM_AGENT=<name>` (or pass `--by`)
so mutations are attributed to you — in `## Log` lines and as the git author.
`WM_DIR` overrides the memory location (default `~/taskmem`). `WM_OFF=1`
disables the memory for a session/folder (mutations refused, digest silent) —
set it in a folder's `.claude/settings.json` `env` to never track there;
`taskmem session off` does the same for one live session.

| Command | Purpose |
|---------|---------|
| `taskmem new <type> <title> [k=v …] [--body -\|text]` | create; prints the item with `id` |
| `taskmem bug <title> [k=v …] [--body -\|text]` | file a defect against taskmem itself: `type=bug`, `status=inbox`, `tags=[taskmem-bug]`, auto-stamped build/agent/host. Excluded from digest + dashboard work sections (surfaced as a count and its own section) |
| `taskmem correction <title> [--about <id>] [--body …]` | record that the human had to correct mis-tracked info: `type=correction`, `status=inbox`, `tags=[taskmem-bug, correction]`, `relates:<id>` when `--about` given. Same exclusion as `bug`; review with `--where tags=correction` |
| `taskmem get <id…> [--raw]` | read (JSON or raw markdown) |
| `taskmem set <id> k=v k+=v k-=v [--body …]` | update fields (`k=` clears; `+=`/`-=` edit lists); `--body` replaces the context but **never** the `## Log` section — that is preserved automatically |
| `taskmem log <id> <message>` | append an attributed line to `## Log` |
| `taskmem link/unlink <id> <rel> <id>` | manage directed edges (validates targets) |
| `taskmem links <id>` | outbound + inbound edges |
| `taskmem thread <id> [--all] [--oneline]` | transitive parent/follows lineage, both directions |
| `taskmem chain <id> [--oneline]` | a milestone's steps (descendants via `parent`) ordered by `blocks`, each tagged done/next/blocked; the single next actionable step marked `next` (derived, not stored) |
| `taskmem chain-new <parent> "s1" "s2" …` | create the given steps as children of `<parent>`, parent-linked and blocks-chained in order (first step `next`) |
| `taskmem story <id> [--oneline]` | full context + lineage + merged timeline (git mutations ∪ log lines) |
| `taskmem delegate <id> [--copy] [--fenced]` | handoff prompt for any AI agent; `--copy` → clipboard (raw), `--fenced` → stdout wrapped in a ````text fence for chat display |
| `taskmem find [--where EXPR]… [--sort k:desc,k2] [--limit N] [--offset N] [--fields a,b] [--full] [--count] [--oneline]` | generic query |
| `taskmem search <text> [--limit N]` | full-text, all-tokens-match, scored |
| `taskmem history <id> [--diff]` | git history of one item |
| `taskmem rm <id…>` | hard delete (prefer `status=dropped`) |
| `taskmem archive <id…>` | move out of the working set into `archive/` |
| `taskmem unarchive <id…>` | move back into `items/` |
| `taskmem notify <title> <message>` | OS notification |
| `taskmem session off\|on\|status` | disable/enable mutations for the current session (`CLAUDE_CODE_SESSION_ID`); reads always work |
| `taskmem session undo [--yes]` | revert this session's item changes — delete items it created, restore items it edited; dry-run without `--yes`; skips items another session also touched |
| `taskmem sync` | commit; pull --rebase + push if a remote exists |

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
taskmem find --where "status!=done,dropped" --where "due<=today" --sort due     # due/overdue
taskmem find --where status=waiting --where people=Rahul                        # waiting on Rahul
taskmem find --where "status!=done,dropped" --where "updated<today-14"          # stale
taskmem find --where "links~blocks:" --where "status!=done,dropped"             # blocking items
taskmem find --where type=decision --sort created:desc --limit 10               # recent decisions
taskmem find --where "links!~parent:" --where "links!~follows:" --where type!=project --where "status!=done,dropped"  # independent items
taskmem find --where "links~parent:wm-xxxxxx" --where "status!=done,dropped"    # direct members of a project/thread
```

## Archive

`archive/` holds items moved out of the working set so `find`/`search` stay
fast as closed items accumulate. Both commands scan `items/` only unless
passed `--archived` (archived items then carry `archived: true` in results).
Everything id-addressed — `get`, `set`, `log`, `link`, `history`, `rm`,
`unarchive` — resolves archived items transparently, and `links` reports
edges into the archive instead of showing them as missing. *When* to archive
is agent policy (see AGENTS.md); the infrastructure only provides the move.

## History

Every mutation auto-commits to git with the acting agent as author, so
`taskmem history` and `git log` reconstruct who changed what, when, and why —
without any bespoke history code. `WM_NO_COMMIT=1` batches mutations into a
later `taskmem sync` commit.
