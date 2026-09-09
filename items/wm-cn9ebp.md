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
updated: 2026-09-09T13:13:38Z
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
- 2026-08-24T12:27Z [claude-code] SWEEP 2026-08-24 — BRITTNEY HAS NOW BEEN WAITING 12 DAYS, AND THE PR THIS SHIPS IN HAS ACQUIRED A REAL BLOCKER.

(1) THE REPLY IS STILL UNSENT. Read the full group DM C0B6ZBZG61M today: the last message in the channel is Brittney's, 2026-08-12 18:39 IST — 'the memos have been updated. not sure they will stick but they are in Ramp currently'. Abhishek has not posted since. So she acted on his 'Oh ok - I can do that', then did the extra memo work Frank suggested, and has heard nothing back for twelve days. The 2026-08-12 entry below settled WHAT to tell her (keep the vendor list; the memo tag is an additional branch, never a replacement, because tag-only would drop 206 charges and the tag covers only the Jan-Feb backlog, missing 8 Cursor charges since 2026-03). That answer has simply never been delivered.

(2) PR #6223 IS CHANGES_REQUESTED AND THE REASON IS CONCRETE. Frank Jones reviewed on 2026-08-20 13:04Z with the entire body being: 'This is not how we're doing integration tests anymore. Take a look at any file in edgefocus/integration_tests/md_tests/'. That is a rewrite of the test layer, not a nit — so this item is no longer the one-line change plus test cases the body describes. The PR is out of draft and has kushagrashukla2904 and nakula-efp requested.

(3) A SENTRY BOT FINDING LANDED 2026-08-22 08:25Z THAT DIRECTLY AFFECTS THIS ITEM'S ACTUAL EDIT, severity HIGH, on ingest_ramp_ai_transactions_utils.py:223-226: the vendor-name match is CASE-SENSITIVE. merchant_name comes straight off the Ramp API and is compared with a bare SQL IN against the vendor tuple, so 'OPENAI' or 'openai' would silently miss, while the memo-tag branch alongside it correctly uses LOWER(). This matters precisely because the promise to Brittney is to add 'OpenAI' and 'Anthropic' — adding two names to a case-sensitive matcher inherits the flaw for the two vendors she is waiting on. Fix is to LOWER() both sides, mirroring the memo-tag branch. A second, lower-severity bot note flags that an empty VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER tuple would render 'IN ()' and fail at runtime; latent only, since the tuple is never empty today.

REVISED NEXT STEPS (superseding the ones in the body, which assumed a one-liner): (a) reply to Brittney now — she is owed an answer independent of the PR's state and it should not wait on a test-layer rewrite; (b) add OpenAI + Anthropic WITH case-insensitive matching, not without; (c) rewrite the integration tests to the md_tests/ pattern Frank named.
- 2026-08-24T15:00Z [claude-code] PARTIAL PROGRESS TODAY, BUT THE ACTUAL PROMISE IS STILL UNKEPT. Re-checked PR #6223 and the group DM at 2026-08-24 14:5xZ.

WHAT LANDED (3 commits, 12:59-13:06Z today): 'DEV-970: Match the vendor exception case-insensitively' — the Sentry HIGH I flagged in the entry above is FIXED. The diff now shows vendor.lower() over VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER and LOWER(PARSE_JSON(x.RAW_RESPONSE):merchant_name::STRING) in the SQL, matching the memo-tag branch. Also 'Drop a docstring reference to the deleted integration test' plus a master merge, which addresses Frank's CHANGES_REQUESTED by deleting the old-style integration test.

WHAT DID NOT LAND — AND IT IS THIS ITEM'S WHOLE POINT: the constant is still VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER = ('Cursor',). OpenAI and Anthropic are NOT in it. Everything Brittney was promised on 2026-08-11 is still absent from the code. The silver lining is that the case-insensitivity fix makes adding them genuinely safe now, so this really is the one-line change the body describes — it just has not been made.

BRITTNEY IS STILL UNANSWERED, NOW 13 DAYS. Re-read C0B6ZBZG61M today: the last message is still hers from 2026-08-12 18:39 IST. Nothing has been sent.

PR IS STILL BLOCKED ON PROCESS, NOT CODE: #6223 remains reviewDecision=CHANGES_REQUESTED and mergeStateStatus=BLOCKED. Frank reviewed on 08-20 and has not re-reviewed; pushing fixes does not clear a changes-requested state on its own, so a re-review has to be requested explicitly.

THREE THINGS LEFT, in the order that unblocks fastest: (1) add 'OpenAI' and 'Anthropic' to the tuple — one line, now case-safe; (2) re-request review from fjones1985; (3) reply to Brittney, which is independent of the PR and should not keep waiting on it.
- 2026-08-26T13:10Z [claude-code] SWEEP 2026-08-26 — THE PR SHIPPED WITHOUT THE THING THIS ITEM IS ABOUT, BUT THE RIGHT ANSWER HAS ALSO CHANGED. Read both halves before acting.

(1) PR #6223 MERGED 2026-08-24 21:03Z AND IS LIVE IN PROD, and the vendor list went with it unchanged. Verified on master today: VENDORS_BOOKED_OUTSIDE_THE_EXPENSE_LEDGER = ('Cursor',). OpenAI and Anthropic are NOT there. The case-insensitivity fix DID land (LOWER(merchant) IN (lowered tuple)), so the matcher is now correct — it just has two fewer names in it than Brittney was promised.

(2) BRITTNEY IS NOW 14 DAYS UNANSWERED. C0B6ZBZG61M still ends at her 2026-08-12 18:39 IST message.

(3) THE SUBSTANCE HAS MOVED, AND IT ARGUABLY VINDICATES SHIPPING WITHOUT THEM. The promise was made on 2026-08-11, BEFORE the #efp-ai memo tag existed. What has happened since:
  - Abhishek's own 2026-08-11 message already said OpenAI and Anthropic 'have been categorised correctly since 7th Feb', i.e. their ONGOING spend lands on GL 5510 and needs no vendor exception at all. Only the Jan-Feb 2026 backlog (3 OpenAI + 7 Anthropic = 10 charges) sat outside it, and that is precisely what could not be re-coded once QBO had synced.
  - Brittney then memo-tagged that history, and the prod backfill confirms it works: PROD attribution is GL 5510 = 218, vendor rule only = 45, memo tag only = 18. The 18 memo-only rows are the Jan-Feb backlog the vendor names were going to rescue.
  So the vendor exception is genuinely Cursor-specific — Cursor is the one AI vendor coded to 'Due From Funds' rather than 5510 — and adding OpenAI/Anthropic would now be redundant with the GL rule for new spend and redundant with the memo tag for old spend.

WHAT THIS MEANS FOR THE ITEM: the code half is probably CORRECT AS SHIPPED and should not be changed without a reason. The reply half is the entire remaining obligation, and it is now a better message than the one drafted on 2026-08-12: tell Brittney the two vendors did not need adding after all, because the memo tags she applied are doing exactly that job (18 charges recovered in prod), and thank her for it. Do NOT send the older 'keep the vendor list, we still need it' framing — that was about Cursor and would read as if her memo work was wasted.

STILL GENUINELY OPEN AND WORTH INCLUDING IN THE REPLY: per the DEV-970 prod log, Brittney was also going to re-code the Jan-Feb OpenAI (3) + Anthropic (7) charges in Ramp, which would move ~10 rows off the memo rule onto the GL rule. Worth telling her that is now optional rather than needed, so she does not spend time on it.
- 2026-09-09T13:13Z [claude-code] Slack sweep 2026-09-09: re-read the group DM (C0B6ZBZG61M, Frank + Brittney). The last message in that DM is Abhishek's own, 2026-08-11: 'We get the memo field via the API. We can have something like #efp-ai anywhere in the memo. Brittney - is this feasible?' Brittney never answered. So there are two threads here, not one: (a) the promise Abhishek made — 'Oh ok - I can do that' — to add OpenAI + Anthropic to the vendor exception like Cursor, which is his to ship and needs no answer from her; (b) Frank's cheaper alternative, a #efp-ai memo tag, which is stalled waiting on Brittney and needs a nudge. Do (a) regardless; it works whether or not the memo tag ever happens.
