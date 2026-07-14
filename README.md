# workmem — an AI-native shared work memory

A shared external brain that AI agents collaboratively maintain. Work items —
tasks, follow-ups, reminders, questions, decisions, ideas — are inferred from
conversations and work, then created, enriched, and closed by agents. Humans
read and edit it freely, but almost never have to say "create a task."

```
~/workmem/
  bin/wm            # the entire infrastructure: one ~550-line Python CLI, zero deps
  items/            # one markdown file per work item (the actual memory)
  prompts/          # scheduled-agent prompts (daily/weekly review)
  SCHEMA.md         # STABLE: data model + CLI contract (rarely changes)
  AGENTS.md         # EVOLVING: behavioral protocol for every agent
  README.md         # this file (humans)
  .logs/            # scheduler output (gitignored)
```

## The 30-second mental model

- **Files are the truth.** Each item is a human-readable markdown file with
  flat frontmatter. Grep it, open it in Obsidian, edit it by hand — all valid.
- **The CLI is the API.** `wm` gives generic create / get / set / find /
  search / link / log / history / notify. Nothing task-specific.
- **Git is the history.** Every mutation auto-commits, authored as the acting
  agent. `wm history <id>` answers "who changed this and why."
- **Prose is the business logic.** Prioritization, capture rules, reviews,
  dedup, planning — all live in AGENTS.md as instructions any model can
  follow, not in code.

## Quickstart (humans)

```bash
wm find --where "status!=done,dropped" --sort due --oneline   # what's open
wm search "pricing"                                           # find anything
wm new task "Ship the pricing page" due=today+3 tags=pricing  # manual capture
wm get wm-xxxxxx --raw                                        # read one item
wm history wm-xxxxxx                                          # who did what
```

`wm` is symlinked into `~/.local/bin`. For agents, the stable path is
`~/workmem/bin/wm`. More query recipes are in [SCHEMA.md](SCHEMA.md).

## Architecture: what is infrastructure vs. AI, and why

The dividing line: **infrastructure provides deterministic capabilities;
agents provide judgment.** If a rule would need tuning, context, or taste, it
must not be code.

| Concern | Lives in | Why |
|---|---|---|
| Storage, mutation, atomic writes | `wm` (code) | Determinism required; data loss is unacceptable. |
| Query engine (`--where`, sort, paginate) | `wm` (code) | Mechanical predicate evaluation. Generic on purpose: `get_due_today()` is policy; `due<=today` is arithmetic. |
| History / audit | git | Version control is a solved problem; auto-commit per mutation + agent-as-author gives attribution for free instead of a bespoke event store. |
| Link integrity (edges, validation) | `wm` (code) | Referential mechanics. Edges are stored one-directional and the reverse is *derived* at query time — no double-write consistency bugs. |
| Due-date format validation | `wm` (code) | A malformed date silently breaks range queries; format checks are the storage layer's job (like a column type). Nothing else is validated. |
| Notifications, scheduling | OS (`wm notify`, cron) | Delivery and clocks are deterministic; *what deserves attention* is the agent's call. |
| Commitment detection, capture | AGENTS.md (prose) | Pure language judgment ("we'll revisit next week" → follow-up). |
| Prioritization, daily/weekly planning | AGENTS.md + prompts | Context-dependent taste; changes often; must be tunable by editing text, not code. |
| Dedup, decomposition, blocker analysis, workload balance | AGENTS.md (prose) | Semantic reasoning over items; exactly what LLMs are for. |
| Vocabulary (types, statuses, rels) | SCHEMA.md (prose) | Conventions agents keep consistent; enforcing enums in code would block evolution of the vocabulary. |

Decisions that follow from the same line:

- **Markdown + flat frontmatter, one file per item** — human-readable,
  git-diffable, editor-friendly, trivially portable; per-item files keep
  concurrent agents from conflicting. The frontmatter is a flat YAML subset
  so the parser stays ~50 lines and zero-dependency.
- **Linear scan instead of an index** — at personal scale (thousands of
  items) a full scan is milliseconds. An index is a cache you have to keep
  coherent; add SQLite behind the *same* CLI surface only if scale ever
  demands it.
- **CLI as the interface, not a library or MCP server** — every agent
  framework (Claude, Codex, Gemini, local models, cron scripts) can exec a
  command and parse JSON. This is what makes agents interchangeable clients.
  An MCP server later is a thin wrapper mapping tools 1:1 onto these
  commands — an adapter, not a replacement.
- **Stable vs. evolving layers are physically separate files** — `bin/wm` +
  SCHEMA.md are the contract; AGENTS.md + prompts/ are expected to be
  rewritten as models improve. Swapping ChatGPT→Claude→Gemini touches zero
  infrastructure.
- **Open schema** — unknown frontmatter fields are preserved, so integrations
  extend the data model without code changes.

Explicitly rejected: a database (opaque, not hand-editable, needs migrations);
specialized endpoints like `get_overdue()` (policy creep into infra — the
generic grammar already expresses them); bidirectionally-stored links (silent
corruption when one side is hand-edited); default filters like "hide done"
(even defaults are policy — agents pass their own filters); business rules in
a scheduler (cron only decides *when* an agent wakes, never *what matters*).

## Scheduling (the one manual step)

The scheduler just wakes an agent with a prompt; all judgment is in the
prompt + AGENTS.md. With Claude Code, `crontab -e` and add:

```cron
30 8 * * 1-5 WM_AGENT=daily-review  "$HOME/.local/bin/claude" -p "$(cat $HOME/workmem/prompts/daily-review.md)"  --allowedTools "Bash" >> $HOME/workmem/.logs/daily.log 2>&1
0 17 * * 5   WM_AGENT=weekly-review "$HOME/.local/bin/claude" -p "$(cat $HOME/workmem/prompts/weekly-review.md)" --allowedTools "Bash" >> $HOME/workmem/.logs/weekly.log 2>&1
```

(Adjust the `claude` path — `which claude` — and permission flags to taste.
Any headless runner works the same way: `codex exec`, `gemini`, or a script
that calls a model API and executes the returned commands. Claude Code cloud
"routines" are an alternative to local cron.)

## Multi-machine

```bash
cd ~/workmem && git remote add origin <your-private-repo> && wm sync
```

`wm sync` commits, pulls --rebase, pushes. Per-item files make conflicts rare;
when they happen, git surfaces them and any agent can resolve semantically.

## Extending

- **New agent** (meeting bot, research agent…): point it at AGENTS.md and
  give it shell access. That's the whole integration.
- **GitHub**: a webhook/poller hands events to an agent ("PR #142 merged")
  which finds the matching item and closes it, stamping `github_pr: 142`.
- **Meetings/Slack/email**: pipe transcripts or threads through any model
  with AGENTS.md as the system prompt; it captures commitments with
  `source=meeting:…` / `channel: #…`.
- **MCP**: wrap `new/get/set/find/search/log/link` as MCP tools shelling out
  to `wm` (~50 lines) for agents that prefer tool-calling over shell.
- **Human UI**: the files are the UI (Obsidian vault, `wm find --oneline`),
  or generate views from `wm find` JSON.
