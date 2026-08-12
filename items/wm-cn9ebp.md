---
id: wm-cn9ebp
type: followup
title: Add OpenAI + Anthropic to the Ramp vendor exception, as promised to Brittney
status: next
size: xs
people: [Brittney]
tags: [ai-billing, needs-reply]
links: [parent:wm-gcdq6k]
refs: [PR-6223=https://github.com/edgefocus/efp/pull/6223]
created: 2026-08-12T13:30:57Z
updated: 2026-08-12T13:31:09Z
source: claude-code
label: Ramp vendor exception
---

Brittney asked in the group DM (C0B6ZBZG61M) on 2026-08-11 21:49 IST: "There isn't an easy way to change the category in Ramp once transactions have been synced into QBO. Can you add the other two vendors similar to Cursor?" — meaning OpenAI and Anthropic, whose historical charges sit under the parent `5500 – Software & Technology` rather than `5510 – AI Software` and cannot be re-coded retroactively. Abhishek answered "Oh ok - I can do that." at 21:55 IST. That promise is not yet kept.

PR #6223 (`DEV-970: Keep AI spend that is booked outside the expense ledger`) is where it goes. It currently ships `VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER = ("Cursor",)` and nothing else, matched as a fourth branch of the existing predicate so the WHERE clause stays a single flag test. Adding two names is a one-line change plus test cases — the PR already has the `cursor-lookalike` case proving the match is exact rather than substring, so mirror that for the new names.

Two things worth deciding before just appending them. First, the PR body argues deliberately for keeping the list short, because "a name here is invisible to the account rule, and that rule is what lets a newly approved tool appear on its own once finance tags it" — OpenWhispr was found that way with no code change. Second, and more importantly, the memo-tag approach may make the whole list unnecessary: Brittney updated the Ramp memos on 2026-08-12 18:40 IST so an `#efp-ai` marker can carry the signal instead, which is what Frank actually wanted. See [[wm-gcdq6k]] for that thread. If the memo tag survives the QBO sync, the right move is arguably to tell Brittney the vendor list is no longer needed rather than to extend it.

Either way Brittney is owed an answer, since she acted on his "I can do that".

## Next steps
1. Read the output of `~/probe_memo_tags.py` on dpx (a parallel session ran it today) to find out whether `#efp-ai` actually arrives on the Ramp API payload.
2. If the memo tag works, reply to Brittney that the vendor list is not needed and the memo marker covers it; if it does not, add `"OpenAI"` and `"Anthropic"` to `VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER` with matching exact-match test cases.
3. Take PR #6223 out of draft either way — draft status is the only thing blocking it.

## Links
- PR #6223 — https://github.com/edgefocus/efp/pull/6223
- Group DM thread — https://edgefocuspartners.slack.com/archives/C0B6ZBZG61M/p1786540199026419
- DEV-970 — https://linear.app/edge-focus/issue/DEV-970/add-tracking-of-ai-billing-to-slack
