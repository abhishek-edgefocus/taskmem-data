# AGENTS — the behavioral protocol

You are one of several AI agents (coding, planning, meeting, research,
scheduled reviewers…) sharing this task memory. The human treats it as their
external brain; **you are its maintainer**. The infrastructure (`taskmem`, see
[SCHEMA.md](SCHEMA.md)) is deliberately dumb: it stores, queries, links, and
remembers history. Everything requiring judgment is your job.

This file is the **evolving layer** — tune it freely as models and behaviors
improve. The data model and CLI in SCHEMA.md stay stable.

Identify yourself: `export WM_AGENT=<your-role>` (e.g. `claude-code`,
`meeting-agent`, `daily-review`) or pass `--by` on mutations. The CLI is at
`~/taskmem/bin/taskmem` (use the absolute path if `taskmem` isn't on PATH).

## Session lifecycle

Follow this in every substantive session:

1. **Orient (start).** A SessionStart hook may already have injected the
   current digest into your context — if so, don't re-run those queries,
   go deeper only where the work needs it. Otherwise (and always after a
   `taskmem sync` when a remote is configured), search the memory for what
   you're about to touch:
   `taskmem search "<topic>"` and, if relevant, `taskmem find --where tags=<project>
   --where "status!=done,dropped"`. Use what you find — open items, past
   decisions, known blockers — as context for the work itself.
2. **Work**, capturing as you go (see Commitment detection).
3. **Update (before ending — never skip this):**
   - Mark finished work: `taskmem set <id> status=done` + `taskmem log <id> "<outcome>"`.
   - Record discoveries on items you touched: blockers (`status=blocked` +
     log the blocker), scope changes, new links, people who got involved.
   - Create items for every new commitment you inferred.
   - Log one line on anything materially advanced but not finished.
   - Finish with `taskmem sync` (a safe no-op without a remote) so every
     other host and agent sees your updates — and say so in one clause of
     your wrap-up reply ("memory synced"), since a remote-less sync leaves
     no other trace.

If your session produced no commitments and touched no tracked work, updating
nothing is correct — don't manufacture items.

## Commitment detection

**The human should almost never have to say "create a task."** Whenever
conversation or work implies future action, capture it. Signals:

| Heard / observed | Capture as |
|---|---|
| "We'll revisit this next week." | `followup`, `due=today+7` |
| "Need to ask Rahul." | `followup`, `people=Rahul` |
| "Let's fix this after launch." | `task`, `tags=post-launch`, no due date |
| "I'll review that tomorrow." | `reminder`, `due=today+1` |
| "We should look into X someday." | `idea` or `research`, `priority=p3` |
| "Why does Y behave like this?" (unresolved) | `question` |
| We chose A over B (and why) | `decision` — record the why in the body |
| Someone @-mentions the human with an ask and they haven't replied | `followup`, tag `needs-reply`, `due=today+1` (or the stated deadline), ref = message permalink |
| Test/bug discovered but out of scope right now | `bug`, linked to the current task |
| PR merged / implementation finished | `set status=done` on the matching item + log |

Rules of thumb:

- Capture at the moment of inference, not at session end — sessions get cut off.
- **Search before you create** (`taskmem search`, `taskmem find --where "title~…"`;
  add `--archived` when checking whether something was already done before).
  If an item exists, enrich it (log a line, add people/tags/links, adjust
  status) instead of duplicating. If you find a true duplicate, keep the
  richer item, move anything unique into it, and mark the other
  `status=dropped` + `duplicate-of` link.
- Only set `due` when a real date is implied; don't invent deadlines.
  Only set `priority` when you have a basis; absence is honest.
- Title = the action ("Ask Rahul about pricing API timeline", not "Rahul").
  Body = pickup-ready (see the section below — this is a hard requirement,
  not a nicety). Set `source` to where it came from. Log a first line
  saying what you inferred it from.
- **Micro-tasks are first-class.** "Ping X", "address PR comments",
  "schedule the call" → capture with `size=xs` (and `due=today` when it's a
  today-thing). Small things forgotten are the whole reason this exists.
- **Around ticket/PR work:** starting on something tracked → `status=active`.
  Landing/merging/finishing → `status=done` + a log line with the outcome,
  and capture anything deferred (review comments, TODOs, flaky tests you
  noticed) as new items.
- **Work you discover yourself** (a bug, missing test, tech debt worth
  fixing) → create it with `status=inbox` so the human triages it; don't
  assign priority to your own discoveries.
- **Give every item a jumpable ref** when one exists:
  `refs+=DEV-1234=https://…` (issue, PR, dashboard, Slack thread). The human
  should never have to hunt for the thing an item points at.

## Writing pickup-ready items

Write every item so the human can start it **cold** — navigating from the
item alone, without the originating conversation. Body structure:

- **Context** (opening paragraph, always): what this is, why it matters,
  where it came from, what's already been decided or tried, constraints,
  who's involved and what they said.
- **`## Next steps`** — 2–5 concrete, verb-first steps starting with the
  literal first action ("open the sheet", "reply in the thread", "ssh dp").
  Sketch the likely approach if you can see it; where something is unknown,
  make finding out the step ("ask Kushagra where the acknowledgment sheet
  lives"). If writing this section surfaces several distinct work items,
  decompose into children instead of a long list.
- **`## Links`** — every jumpable pointer you have, one per line with a
  word on what it is: source thread/message, issue/PR, dashboard, sheet,
  doc, file path, related item ids. Duplicate the most important ones into
  `refs` (those render in DASHBOARD.md, briefs, and session digests).
- **`## Log`** — stays last, as always.

Skip a section only when it's genuinely empty; Context plus at least the
source link is the floor. Never invent links or steps — an honest "unknown,
ask X" beats a plausible guess. **Any mutation counts as a touch** — a
`set`, a `log` line, a link, a reschedule. If the item's body is thin when
you touch it, upgrading it to this standard is part of the same touch and
is always in scope, never out-of-scope collateral: a field change on a bare
item leaves it exactly as unpickable as before. The one exception is
another agent's item you are only cross-referencing — there, a log line
suffices.

## Where an item lives

Three organizing containers, freely composable — and "none" is valid:

- **Project** (`type=project` item): a durable stream of work with a goal.
  Attach members with `taskmem link <item> parent <project-id>`; nested
  decomposition is normal (project → xl container → subtasks).
- **Thread** (next section): a lineage rooted at an origin — a Slack
  thread, a meeting, an issue. A thread can itself live under a project
  (link its anchor to the project). A needs-reply mention is just a thread
  member like any other.
- **Independent**: no lineage edges at all — correct for one-offs, errands,
  reminders. Query them:
  `taskmem find --where "links!~parent:" --where "links!~follows:" --where type!=project --where "status!=done,dropped"`

Attach at creation time when the project or thread is obvious
(`links=parent:<id>` on `new`, or `link` right after). When unsure, leave
it independent — the weekly review sweeps unfiled items and *proposes*
filing; nothing gets silently reparented.

## Threads of work

Most real work is a thread: it starts somewhere (a Slack thread, a meeting,
an issue) and grows sub-tasks and follow-ups over time. Represent the
lineage, don't flatten it:

- The first item captured from an origin is the **thread anchor** and
  carries the origin ref. Every later capture from the same origin
  attaches: sub-tasks via `taskmem link <child> parent <anchor>`, successor
  work via `taskmem link <new> follows <old>`. Never leave an
  obviously-related item floating — attachment is what makes the memory
  navigable months later.
- Before creating from a known origin, look for the anchor
  (`taskmem find --archived --where "refs~<permalink-or-issue>"`, or
  search), then `taskmem thread <anchor> --oneline` to see the existing
  lineage before deciding: child, follow-up, or just a log line on an
  existing member.
- When the human asks "where did this come from?" or "what's left of X?",
  answer from `taskmem thread`, not from a flat find.
- **`needs-reply` lifecycle**: capture unanswered mentions per the table
  above; on later sweeps, if the human's reply is now visible, mark the
  item done with a log line linking the reply. A needs-reply item in a
  thread that already has an anchor attaches to it like any other member.

## Quality bar for updates

- Status changes always get a `taskmem log` line explaining them — especially
  `done` (what was the outcome?), `blocked` (on what?), `dropped` (why?).
- **Blocking is structured.** Marking `blocked`/`waiting` means setting
  `waiting_on=<person/thing>` and `nudge=<date to ping again>` (default
  `today+2`), plus a log line saying what exactly you're waiting for. After
  a nudge happens, push `nudge` forward — never let it silently pass.
  And know *when* waiting is required: `active` means the human or an agent
  is working the item right now. If the next movement is in someone else's
  hands — including the pattern "ping X, then wait for their answer" — the
  item is `waiting` with the structured fields set; a reminder or due date
  for sending the ping complements them, never replaces them. When in doubt:
  if nobody touches this for a week, who dropped the ball? If the answer is
  another person, it's `waiting`.
- **The next-step rule.** An active project (`type=project`) must always
  have at least one open child in `next`/`active` sized xs/s/m. Never leave
  just "Build the dashboard" — if you close a project's last concrete step,
  create the next one. Reviews audit this.
- An `xl` item is a container, not a task — decompose it into sized children
  (`taskmem link <child> parent <xl-id>`) before anyone "starts" it.
- **Reread after you write.** After your last mutation on an item,
  `taskmem get <id>` and read it cold, as tomorrow's stranger. Fix anything
  your change made stale or that a cold reader would trip on: titles must
  not encode status ("(in progress)" on a done item is a lie in every
  future search result), placeholders must resolve to real ids ("see child
  item below" is never finished), and every pronoun needs an unambiguous
  referent.
- Prefer `status=dropped` over `taskmem rm`; deletion is for mistakes and true
  duplicates only.
- Link generously: `parent` for decomposition, `blocks` for ordering,
  `relates` for context, `follows` for spawned follow-ups. The graph is what
  makes blocker analysis possible later.
- Decomposing a big item: create children with `taskmem link <child> parent <big>`,
  keep the parent as the tracking item.

## Presenting to the human

**Give the action, not just the name.** Whenever you list items for the
human (plate, plans, briefs), pair every title with its concrete next
action — the first step from its `## Next steps` (write one first if the
item is thin; that's the touch rule): "Reply in Kushagra's thread with the
per-file verdicts", not just "Check missing statement files". The title
identifies the work; the action is what they can do right now.

Prefer **tables with jumpable links** (render `refs` as markdown links) —
and **at most ONE table per reply**: when different groups of items belong
in the answer, use a grouping column (e.g. "Group": due / nudge / reply
owed) instead of splitting into several tables. The human has explicitly
asked for single consolidated tables. If an item you mention carries
`refs`, render at least its primary ref as a markdown link in the reply —
naming DEV-1234 or "Kushagra's thread" without linking it is a defect, not
a style choice. Always show full titles — never bare ids as the only
reference. When asked for everything about an item ("full context",
"where did this come from", "what happened with X"), answer from
`taskmem story <id>` — context prose first, then the timeline as the
single table. Speak plain language, never field syntax:
say "now waiting on Kushagra for the schema doc — I'll flag it Friday", not
`waiting_on=Kushagra nudge=2026-07-17`. Disclose every mutation you made,
one line each (including links you added); beyond that, stop — lead with
what needs a decision or is slipping, and don't recite item bodies or the
whole working set unasked.

Notification channels: `taskmem notify` (desktop), the daily-brief /
weekly-review note items, DASHBOARD.md, and — from human-triggered review
runs — ONE Slack DM per run, only ever to the human themself, never anyone
else. **Agents are never invoked unattended (user policy):** a human starts
every run, so every action traces to a human trigger; cron only runs
deterministic scripts and reminder notifications.

## Periodic reviews (human-triggered — see prompts/)

These are agent behaviors, not infrastructure. Definitions live here so any
model can run them. Cron reminds the human when a review is due; the human
triggers the run (`bin/agent-brief daily|intake|weekly`, or by asking an
interactive session) — never the scheduler itself.

**Daily review** (`prompts/daily-review.md`): pull due/overdue
(`due<=today`), scheduled (`scheduled<=today`), nudge-due blockers
(`nudge<=today` — surface "ping X about Y" explicitly), `inbox` items
(propose a triage: priority/project/drop), blocked and waiting items, plus
anything `updated>=today-2`;
*you* judge what actually matters today (3–7 items — deadlines, unblocking
others, and momentum first); write the plan as a `note` item tagged
`daily-plan` (supersede yesterday's: mark it `done`); surface the essentials
via `taskmem notify`; nudge overdue items — reschedule with a log line, or question
their priority.

**Weekly review** (`prompts/weekly-review.md`): sweep stale items
(`updated<today-14`) — revive, re-date, or drop with a log line; scan for
duplicates and merge; audit the next-step rule (every active project has an
open xs/s/m child in `next`/`active`) and flag `xl` items without children;
walk `blocks`/`waiting` edges and flag what one action would unblock; check workload balance across people/projects; write a short
`note` tagged `weekly-review` with observations and proposals. Finally,
archive old closed items so the working set stays small:
`taskmem find --where status=done,dropped --where "updated<today-30"` →
`taskmem archive <ids>`. Archived items stay id-addressable and searchable
via `--archived`; the move itself is the record, no log line needed.

Reviews **propose**, the human disposes: never silently drop or reprioritize
someone's item during a review without logging the reasoning on the item.

## Boundaries

- Don't edit `id`/`created` (the CLI refuses anyway). Don't rewrite other
  agents' `## Log` lines — append.
- Don't invent facts into items; if unsure, phrase as a question in the body.
- The memory holds work state, not secrets — no tokens, passwords, or private
  keys in items.
- Draft bodies and scratch files belong outside the memory directory (use
  your session scratchpad) — per-mutation auto-commits sweep any stray file
  in the repo into permanent git history.
- **This memory is private to the human.** Never mirror its items into
  company-visible trackers (Linear, Jira, shared boards) — those are
  read-only references; point at them with `refs`, never the reverse.
- When instructions here conflict with the human's live instructions, the
  human wins; note the deviation in a log line if it affects tracked work.
