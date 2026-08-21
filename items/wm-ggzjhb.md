---
id: wm-ggzjhb
type: correction
title: OpenRoad 4923612: I called the legacy datastore wrong when it was right — PR #6413 dates that payoff 35 days early
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-ay9uu3]
created: 2026-08-21T16:18:08Z
updated: 2026-08-21T16:18:08Z
source: claude-code
label: OpenRoad 4923612
---

I claimed the OpenRoad legacy datastore was lagging and that our 2025-04-22 was "arguably the more accurate" date. That is false. I asserted it from an inference — legacy stamped two loans on the same day — without ever checking the balance history.

Ground truth: the legacy open_positions datastore is partitioned one file per as_of_date and carries daily principal back to 2023. For 4923612 the balance was 4,018.99 on 2025-04-21, fell to 3,659.39 on 2025-04-22, then sat UNCHANGED at 3,659.39 every day through 2025-05-26, and the loan goes closed on 2025-05-27 — exactly legacy's date. The 2025-04-22 payment of 397.06 was an ordinary instalment, not the payoff. The loan was closed ~5 weeks later by a non-payment mechanism (TOTAL_PRINCIPAL_PAID 21,945.30 exceeds ORIGINATION_PRINCIPAL 20,445.19, so an adjustment is involved).

So we date that payoff 35 days EARLY. Snowflake is worse than the datastore on that row: the equal-or-better principle IS violated, on exactly one loan.

I then ground-truthed all 13 censored loans the same way (day before our date: open with non-zero balance; on our date: closed). 12/13 pass; only 4923612 fails. The closing-payment fallback's premise — the last payment is the one that closed the loan — holds 12 times and fails once, and nothing on the tape distinguishes the two cases.

Method note, the reason this slipped: validating against legacy's fully_paid_date stamp is the weak test. It only tells you whether you agree with legacy, not whether either of you is right. The open_positions daily balances are the actual oracle. Use those.

Proposed fix (not applied, awaiting his call): the 13 censored loans are a permanently closed set — the tape starts 2026-06-29 with all 35 loans already present, so no future loan can ever be left-censored. Seed those 13 dates explicitly from the verified balance history and keep the status-transition derivation for everything from the tape onward. Exact for all 13, finite, auditable, correct independently of legacy. The weaker alternative is to correct only 4923612 and leave the inference in place for the rest.

PR #6413 body updated with a WARNING callout stating the defect and "do not merge until resolved". Evidence scripts: ~/claude-ws/dev-1539/notes/balance_history.py and verify_all13.py.


## Environment
- taskmem: 5c672d7
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-21T16:18:08Z
- corrected item: wm-ay9uu3
