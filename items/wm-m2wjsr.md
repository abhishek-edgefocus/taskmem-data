---
id: wm-m2wjsr
type: task
title: Backfill the null status_at_purchase rows in silver.positions for northpond (DEV-1522)
status: next
priority: p2
size: s
people: [Abhijeet]
tags: [northpond, data-quality]
links: [parent:wm-j523sq]
refs: [DEV-1522=https://linear.app/edge-focus/issue/DEV-1522/fix-northpond-status-at-purchase, PR-6207=https://github.com/edgefocus/efp/pull/6207]
created: 2026-08-11T08:49:02Z
updated: 2026-08-11T08:49:02Z
source: claude-code
label: northpond status_at_purchase nulls
---

Filed by **Abhijeet** on 2026-08-10 14:55Z, assigned to Abhishek. Backlog, unstarted.
Branch name already reserved: `abhishek/dev-1522-fix-northpond-status_at_purchase`.

The ticket in full: a few rows in `silver.positions` have a NULL `status_at_purchase`.
PR #6207 adds validations to stop new ones appearing, but **the existing offenders still
need fixing** — that remediation is what this ticket is for, and it is the half a
validation PR does not do.

Not yet established (do this before scoping): how many rows, which loans, which funds, and
whether they cluster around a known event — a purchase-tape gap, the efhyf/experimental
split, or the 2-8 day lag between purchase and the loan appearing on the daily tape
([[wm-k3wt84]], done). A validation that starts failing on legitimately-NULL historical
rows would be a second problem.

Captured here because it was assigned by someone else and had no taskmem item — nothing in
Slack mentions it.
