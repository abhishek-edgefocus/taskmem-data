# taskmem — an AI-native shared task memory

A shared external brain that AI agents collaboratively maintain. Work items —
tasks, follow-ups, reminders, questions, decisions, ideas — are inferred from
conversations and work, then created, enriched, and closed by agents. Humans
read and edit it freely, but almost never have to say "create a task."

```
~/taskmem/
  bin/taskmem          # the core: one zero-dependency Python CLI
  bin/session-context  # Claude Code hook — injects task state into every session
  bin/dashboard        # regenerates DASHBOARD.md (glanceable view)
  bin/agent-brief      # headless cron runner for the review agents
  install.sh           # idempotent machine setup (symlinks, hooks, cron)
  items/               # one markdown file per work item (the actual memory)
  archive/             # closed items moved out of the working set
  prompts/             # scheduled-agent prompts (daily/weekly review)
  DASHBOARD.md         # generated view — never edit by hand
  SCHEMA.md            # STABLE: data model + CLI contract (rarely changes)
  AGENTS.md            # EVOLVING: behavioral protocol for every agent
  README.md            # this file (humans)
  .logs/               # scheduler + hook logs (gitignored)
```

## The 30-second mental model

- **Files are the truth.** Each item is a human-readable markdown file with
  flat frontmatter. Grep it, open it in Obsidian, edit it by hand — all valid.
- **The CLI is the API.** `taskmem` gives generic create / get / set / find /
  search / link / log / history / notify. Nothing task-specific.
- **Git is the history.** Every mutation auto-commits, authored as the acting
  agent. `taskmem history <id>` answers "who changed this and why."
- **Prose is the business logic.** Prioritization, capture rules, reviews,
  dedup, planning — all live in AGENTS.md as instructions any model can
  follow, not in code.

## Quickstart (humans)

```bash
taskmem find --where "status!=done,dropped" --sort due --oneline   # what's open
taskmem search "pricing"                                           # find anything
taskmem new task "Ship the pricing page" due=today+3 tags=pricing  # manual capture
taskmem get wm-xxxxxx --raw                                        # read one item
taskmem history wm-xxxxxx                                          # who did what
```

`taskmem` is symlinked into `~/.local/bin`. For agents, the stable path is
`~/taskmem/bin/taskmem`. More query recipes are in [SCHEMA.md](SCHEMA.md).

## Setup on a fresh machine

Requirements: `python3` (3.9+) and `git`. The CLI has zero Python
dependencies. An AI agent can run this whole section unattended.

The short way:

```bash
git clone <your-private-remote> ~/taskmem
~/taskmem/install.sh          # symlinks, Claude Code session hooks, CLAUDE.md pointer
~/taskmem/install.sh --cron   # …plus review agents, autosync, dashboard refresh
```

Manual equivalent (or for non-Claude runners):

```bash
git clone <your-private-remote> ~/taskmem   # or copy the folder; any path works
mkdir -p ~/.local/bin
ln -sf ~/taskmem/bin/taskmem ~/.local/bin/taskmem
ln -sf ~/taskmem/bin/taskmem ~/.local/bin/tm
chmod +x ~/taskmem/bin/taskmem              # in case the clone dropped the bit
tm find --count                             # smoke test — prints {"count": N}
tm notify "taskmem" "setup complete"        # verify notifications fire
```

Notes for the agent doing the setup:

- The binary is **self-locating**: it manages the `items/` directory next to
  wherever it lives, so any clone path works without configuration. Set the
  `WM_DIR` env var only if binary and data must live apart.
- If `~/.local/bin` isn't on PATH, either add it
  (`export PATH="$HOME/.local/bin:$PATH"` in the shell profile) or use the
  absolute path — scripts and cron entries should prefer the absolute path
  anyway.
- Starting from nothing instead of a clone? `taskmem init` creates `items/`
  and the git repo (docs only come with a clone).
- `wm-` item-id prefixes and `WM_*` env vars are stable engine identifiers —
  do not "fix" them to match the brand name (see "Renaming the tool").

Then **enroll the machine's agents**. For Claude Code, add this block to
`~/.claude/CLAUDE.md`; for other runners, put the equivalent in their
standing-instructions file:

```markdown
# Shared task memory (~/taskmem)

A shared task memory for all AI agents lives at `~/taskmem` — markdown work
items + a generic CLI (`~/taskmem/bin/taskmem`, on PATH as `taskmem` and `tm`).

- **Session start:** when beginning substantive work, check it for relevant
  context: `tm search "<topic>"` / `tm find --where tags=<project> --where "status!=done,dropped"`.
- **During and before ending a session:** follow the protocol in
  `~/taskmem/AGENTS.md` — infer commitments from the conversation, create and
  update items, log outcomes on work you touched, and mark finished things
  done. Set `WM_AGENT=claude-code` (or pass `--by`) when mutating.
- Data model and query grammar: `~/taskmem/SCHEMA.md`.
```

Finally, optional but recommended: install the review crontab entries from
"Scheduling" below, and run `tm sync` once to confirm the remote round-trip.

## Architecture: what is infrastructure vs. AI, and why

The dividing line: **infrastructure provides deterministic capabilities;
agents provide judgment.** If a rule would need tuning, context, or taste, it
must not be code.

| Concern | Lives in | Why |
|---|---|---|
| Storage, mutation, atomic writes | `taskmem` (code) | Determinism required; data loss is unacceptable. |
| Query engine (`--where`, sort, paginate) | `taskmem` (code) | Mechanical predicate evaluation. Generic on purpose: `get_due_today()` is policy; `due<=today` is arithmetic. |
| History / audit | git | Version control is a solved problem; auto-commit per mutation + agent-as-author gives attribution for free instead of a bespoke event store. |
| Link integrity (edges, validation) | `taskmem` (code) | Referential mechanics. Edges are stored one-directional and the reverse is *derived* at query time — no double-write consistency bugs. |
| Due-date format validation | `taskmem` (code) | A malformed date silently breaks range queries; format checks are the storage layer's job (like a column type). Nothing else is validated. |
| Notifications, scheduling | OS (`taskmem notify`, cron) | Delivery and clocks are deterministic; *what deserves attention* is the agent's call. |
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
  demands it. What keeps the scan fast long-term is `taskmem archive`: closed
  items move to `archive/`, out of the working set (weekly-review policy),
  while staying id-addressable and searchable via `--archived`.
- **CLI as the interface, not a library or MCP server** — every agent
  framework (Claude, Codex, Gemini, local models, cron scripts) can exec a
  command and parse JSON. This is what makes agents interchangeable clients.
  An MCP server later is a thin wrapper mapping tools 1:1 onto these
  commands — an adapter, not a replacement.
- **Stable vs. evolving layers are physically separate files** — `bin/taskmem` +
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
prompt + AGENTS.md. `install.sh --cron` installs the whole marker-delimited
crontab block (review agents via `bin/agent-brief`, 15-minute autosync,
weekend dashboard refresh). Manually, with Claude Code, `crontab -e` and add:

```cron
30 8 * * 1-5 WM_AGENT=daily-review  "$HOME/.local/bin/claude" -p "$(cat $HOME/taskmem/prompts/daily-review.md)"  --allowedTools "Bash" >> $HOME/taskmem/.logs/daily.log 2>&1
0 17 * * 5   WM_AGENT=weekly-review "$HOME/.local/bin/claude" -p "$(cat $HOME/taskmem/prompts/weekly-review.md)" --allowedTools "Bash" >> $HOME/taskmem/.logs/weekly.log 2>&1
```

(Adjust the `claude` path — `which claude` — and permission flags to taste.
Any headless runner works the same way: `codex exec`, `gemini`, or a script
that calls a model API and executes the returned commands. Claude Code cloud
"routines" are an alternative to local cron.)

## Multi-host / multi-environment sync

One git remote is the sync bus for every host, dev environment, and agent
type. One-time setup, from any machine that already has the memory:

```bash
# 1. create a PRIVATE repo under your personal profile
#    (https://github.com/new, or: gh repo create taskmem --private)
# 2. wire it up and push:
cd ~/taskmem && git remote add origin git@github.com:<you>/taskmem.git && taskmem sync
```

Every additional host, container, or dev environment just follows "Setup on
a fresh machine" above. From then on `taskmem sync` (commit → pull --rebase →
push) converges everyone:

- **Agents sync automatically** — the session lifecycle in AGENTS.md begins
  and ends with `taskmem sync` whenever a remote exists, so any agent type
  on any host both sees and publishes the latest state.
- **Quiet hosts stay fresh via cron**:
  `*/15 * * * * $HOME/taskmem/bin/taskmem sync >> $HOME/taskmem/.logs/sync.log 2>&1`
- **Conflicts are rare and safe.** One file per item keeps concurrent edits
  apart; when two hosts do touch the same lines, `sync` aborts the rebase
  cleanly back to your local state and reports the file — resolve with
  normal git (or hand it to an agent) and sync again.
- **Offline is fine.** Mutations always commit locally; the next sync
  reconciles.

## Renaming the tool

The brand name is deliberately skin-deep: the script takes its command name
from how it's invoked and finds its data relative to its own location
(`<dir>/bin/<name>` manages `<dir>/items/`). **Engine identifiers never follow
the brand** — the `wm-` item-id prefix, the `WM_DIR` / `WM_AGENT` /
`WM_NO_COMMIT` / `WM_DEBUG` env vars, and git plumbing identities stay fixed —
so a rename touches zero data and breaks zero agent integrations.

To rename `taskmem` → `newname`:

```bash
mv ~/taskmem ~/newname
git -C ~/newname mv bin/taskmem bin/newname
ln -sf ~/newname/bin/newname ~/.local/bin/newname
rm -f ~/.local/bin/taskmem ~/.local/bin/tm
grep -rl taskmem ~/newname --include='*.md' | xargs sed -i '' 's/taskmem/newname/g'
git -C ~/newname add -A && git -C ~/newname commit -m "rename taskmem -> newname"
```

Then update references in `~/.claude/CLAUDE.md`, any crontab entries, and
item bodies that mention paths (`newname find --where "body~taskmem"`).

## Extending

- **New agent** (meeting bot, research agent…): point it at AGENTS.md and
  give it shell access. That's the whole integration.
- **GitHub**: a webhook/poller hands events to an agent ("PR #142 merged")
  which finds the matching item and closes it, stamping `github_pr: 142`.
- **Meetings/Slack/email**: pipe transcripts or threads through any model
  with AGENTS.md as the system prompt; it captures commitments with
  `source=meeting:…` / `channel: #…`.
- **MCP**: wrap `new/get/set/find/search/log/link` as MCP tools shelling out
  to `taskmem` (~50 lines) for agents that prefer tool-calling over shell.
- **Human UI**: the files are the UI (Obsidian vault, `taskmem find --oneline`),
  or generate views from `taskmem find` JSON.
