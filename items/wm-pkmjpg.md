---
id: wm-pkmjpg
type: correction
title: Prediction cron times recorded as UTC are actually Pacific — the CMOP/BEP window is 7 hours later than noted
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-udqmrm]
created: 2026-09-08T14:56:37Z
updated: 2026-09-08T14:56:37Z
source: claude-code
label: Prediction cron times recorded
---

WHAT WE HAD: wm-nyjurp (and the body of wm-udqmrm, which inherited it) states 'the curr_mod cron is 13:30 UTC daily, best_est 14:00 UTC Sundays'.

WHAT IS TRUE: those are Pacific times. The prod cron on dumbledore runs curr_mod at 13:30 PT = 20:30 UTC daily, and best_est at ~14:00 PT = 21:00 UTC on Sundays.

PROOF, two independent clocks on the same event:
- /efs/logs/dumbledore/predictions.log: '2026-09-02T13:33:03.147465-07:00' — note the -07:00 offset.
- Sentry EFP-ERRORS-1QA first seen '2026-09-02T20:33:07.421Z'.
Same run, 13:33 PT = 20:33 UTC. The best_est pair matches too: log 2026-09-06T14:10:20-07:00 vs Sentry 2026-09-06T21:10:24Z. 2026-09-06 was a Sunday, so that was the BEP cron, not an ad-hoc run — and it passes --force (sys.argv: run.py --prediction-type best_est --force).

WHY IT SLIPPED: the log lines carry an explicit -07:00 offset that is easy to read past, and 13:3x appears in both clocks, so the two look interchangeable at a glance.

WHY IT MATTERS: the advice attached to it was 'backfill before 13:30 to get CMOP the same day'. Under the real schedule the daily window closes at 20:30 UTC (13:30 PT), so a backfill run in the European/Indian morning has the whole working day of slack, not none.

## Environment
- taskmem: a800d33
- reported by: claude-code
- host: ip-192-168-1-4.ap-south-1.compute.internal
- when: 2026-09-08T14:56:37Z
- corrected item: wm-udqmrm
