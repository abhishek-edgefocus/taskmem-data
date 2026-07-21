---
id: wm-h7tqbn
type: correction
title: Intake sweep searched Slack 'to:me' only, so already-discharged commitments were reported as new work
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-ugkjx7]
created: 2026-07-21T09:10:20Z
updated: 2026-07-21T09:10:20Z
source: claude-code
label: Intake sweep searched Slack 'to
---

WHAT I RECORDED (2026-07-21 session): created wm-ugkjx7 as a live, open commitment covering three asks from Abhijeet's 2026-07-20 DM — (1) post on #north-pond-tech once datastores are deprecated, (2) send the PR to Frank/Michael so they know the project is done, (3) explicitly highlight the OP and v1/v2 gaps in that announcement. I reported all three to Abhishek as outstanding work.

WHAT WAS ACTUALLY TRUE: all three were already done ~5 hours before the session started. Abhishek posted to #north-pond-tech at 2026-07-21 03:46:47 IST (permalink channel C06RMEK095G). That single @channel message covered every one of them: it named the deprecation PR #5936, announced the Snowflake-backed dashboard and the deprecation of the old one, flagged 'adding support soon for filtering loans by TransUnion (V1) and Experian (V2)' (= the v1/v2 gap), and flagged 'working with Oliv's team to integrate their model's origination predictions' (= the OP gap). Being an @channel post it also served ask (2) — Frank demonstrably read it, DMing Abhishek 19 minutes later at 04:05 about the Oliv page.

ROOT CAUSE — a search-shape defect, not a judgment call. My only Slack sweep was the query 'to:me after:2026-07-19'. That filter returns messages addressed TO the human and structurally CANNOT return the human's own outbound messages. So I saw every inbound ask and none of the replies or actions that discharged them. Every conclusion I drew about what was 'still outstanding' was therefore drawn from evidence that could only ever show the asking half of each exchange. I compounded it by treating the absence of a discharge record in taskmem as positive evidence that nothing had been done, when I had simply never looked where discharge evidence lives.

FIX FOR FUTURE AGENTS (intake sweeps):
1. NEVER conclude an ask is unanswered from a 'to:me' search alone. Always pair it with 'from:me' over the SAME window before creating any needs-reply item — one extra query, and it is the query that decides whether the item should exist at all.
2. For any ask that names a target channel, read that channel directly (slack_read_channel) rather than inferring from DM context. One broadcast post can discharge several separate asks at once — as it did here, where one message closed all three.
3. Treat non-message events as discharge evidence too: a huddle/call starting right after an ask often means it was answered verbally and will never appear as text. (Live example from this same session: a huddle started at 04:06:08, 26 seconds after Frank's 04:05:42 question.)
4. Ordering rule: sweep outbound BEFORE creating items, not after. Creating first and verifying later is what put already-finished work in front of the human.

RELATED: wm-epb27n ('Agents miss existing items and re-do or re-ask about work already handled') is the same failure family but a different mechanism — that one is about not searching taskmem; this one is about not searching the human's own sent messages. Fixing either alone leaves this hole open.

## Environment
- taskmem: 361bf0b
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-21T09:10:20Z
- corrected item: wm-ugkjx7
