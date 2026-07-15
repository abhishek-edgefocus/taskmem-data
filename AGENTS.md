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

1. **Orient (start).** Search the memory for what you're about to touch:
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
| Test/bug discovered but out of scope right now | `bug`, linked to the current task |
| PR merged / implementation finished | `set status=done` on the matching item + log |

Rules of thumb:

- Capture at the moment of inference, not at session end — sessions get cut off.
- **Search before you create** (`taskmem search`, `taskmem find --where "title~…"`).
  If an item exists, enrich it (log a line, add people/tags/links, adjust
  status) instead of duplicating. If you find a true duplicate, keep the
  richer item, move anything unique into it, and mark the other
  `status=dropped` + `duplicate-of` link.
- Only set `due` when a real date is implied; don't invent deadlines.
  Only set `priority` when you have a basis; absence is honest.
- Title = the action ("Ask Rahul about pricing API timeline", not "Rahul").
  Body = enough context to act months later without this conversation.
  Set `source` to where it came from. Log a first line saying what you
  inferred it from.

## Quality bar for updates

- Status changes always get a `taskmem log` line explaining them — especially
  `done` (what was the outcome?), `blocked` (on what?), `dropped` (why?).
- Prefer `status=dropped` over `taskmem rm`; deletion is for mistakes and true
  duplicates only.
- Link generously: `parent` for decomposition, `blocks` for ordering,
  `relates` for context, `follows` for spawned follow-ups. The graph is what
  makes blocker analysis possible later.
- Decomposing a big item: create children with `taskmem link <child> parent <big>`,
  keep the parent as the tracking item.

## Periodic reviews (run by the scheduler — see prompts/)

These are agent behaviors, not infrastructure. Definitions live here so any
model can run them.

**Daily review** (`prompts/daily-review.md`): pull due/overdue
(`due<=today`), blocked, and waiting items plus anything `updated>=today-2`;
*you* judge what actually matters today (3–7 items — deadlines, unblocking
others, and momentum first); write the plan as a `note` item tagged
`daily-plan` (supersede yesterday's: mark it `done`); surface the essentials
via `taskmem notify`; nudge overdue items — reschedule with a log line, or question
their priority.

**Weekly review** (`prompts/weekly-review.md`): sweep stale items
(`updated<today-14`) — revive, re-date, or drop with a log line; scan for
duplicates and merge; walk `blocks`/`waiting` edges and flag what one action
would unblock; check workload balance across people/projects; write a short
`note` tagged `weekly-review` with observations and proposals.

Reviews **propose**, the human disposes: never silently drop or reprioritize
someone's item during a review without logging the reasoning on the item.

## Boundaries

- Don't edit `id`/`created` (the CLI refuses anyway). Don't rewrite other
  agents' `## Log` lines — append.
- Don't invent facts into items; if unsure, phrase as a question in the body.
- The memory holds work state, not secrets — no tokens, passwords, or private
  keys in items.
- When instructions here conflict with the human's live instructions, the
  human wins; note the deviation in a log line if it affects tracked work.
