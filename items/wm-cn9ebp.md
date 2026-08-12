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
updated: 2026-08-12T13:32:07Z
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

## Log
- 2026-08-12T13:32Z [claude-code] ANSWERED WITHIN THE HOUR, AND THE ANSWER IS 'KEEP THE VENDOR LIST'. This item was written speculating that the #efp-ai memo tag might make the vendor exception unnecessary; a parallel session ran the probe against the live Ramp API at 13:19Z and settled it — see the full numbers on [[wm-gcdq6k]]. Summary of what changes here: the tag is real and parses (19 transactions carry it, all dated 2026-01-06..2026-02-12), and 'GL 5510 OR tag' keeps 225 rows where 5510 alone keeps 206, so the tag recovers exactly the 18-charge Jan-Feb backlog Brittney could not re-code. But it does NOT cover ongoing spend: 8 Cursor charges since 2026-03 are missed by both rules, including two in August and one that landed today (2026-08-12, $763.18). Brittney tagged the history, not the future.
SO STEP 2 BELOW IS SUPERSEDED — do not tell Brittney the vendor list is unnecessary. The vendor exception in PR #6223 is still required for ongoing Cursor charges, and the memo tag is an additional branch alongside the GL rule, never a replacement (tag-only would drop 206 charges). What is still genuinely open for Brittney is whether Cursor can be auto-memo'd going forward, which hinges on the unanswered 'Use memo for' dropdown-scope question.
The OpenAI/Anthropic half of the promise is unaffected and still owed.
