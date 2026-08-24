---
id: wm-b9uq8f
type: task
title: Set a MonitoringSchedule on northpond_purchase_tape_v0_csv now the cadence is known
status: open
created: 2026-08-24T12:29:19Z
updated: 2026-08-24T12:29:19Z
source: claude-code
---

A decision recorded on [[wm-9dfnnt]] on 2026-08-11 deliberately deferred this, and its
stated revisit condition has now been met.

**The original decision (Abhishek, 2026-08-11):** do NOT add a MonitoringSchedule to
`northpond_purchase_tape_v0_csv` yet, because the real cadence was not settled — Nate had
said "daily" but it was unknown whether that meant 7-day or business-day, and no real file
had ever landed to observe. The trade-off was accepted explicitly: *until a schedule exists,
a purchase file that silently stops arriving raises no alert; detection is manual.* The
revisit trigger was written down as "once a week or so of real landings shows the actual
pattern".

**The pattern is now observed, 2026-08-24.** Nine consecutive business days of real v0
files, zero misses: 2026-08-11, 12, 13, 14, 17, 18, 19, 20, 21 — each landing between
13:37 and 13:39 UTC. Nothing on 08-15/16 or 08-22/23, both weekends. All nine ingested
cleanly (PROD.BRONZE.STATEMENT_FILES, one file per day, all STATUS=rows_added).

So the answer to the question that blocked the decision is **WEEKDAY, not DAILY**. Setting
DAILY would page every Saturday and Sunday.

**Why this matters now more than it did on 08-11.** Then, one missed file meant one missing
test batch. Now the feed carries 265 purchased EDGEX loans and is the input to fund
attribution for a live deal ([[wm-d7m3xz]]), so a silent stop is a reporting gap on real
money, still detected only by somebody happening to look.

The 08-11 decision also left a specific trap to avoid: **do not set `start_date` earlier
than the first real file** (2026-08-11) or the schedule back-alerts for every prior day.
`grace_days` defaults to 3.

## Next steps
1. Add a MonitoringSchedule to the `northpond_purchase_tape_v0_csv` rule with
   `frequency=WEEKDAY`, `start_date=2026-08-11`.
2. Confirm against the nine known-good days that it produces zero retrospective alerts
   before it goes anywhere near prod.
3. Consider whether the sibling Oliv feeds want the same treatment — per [[wm-dfec2v]] the
   issuance and both Nelnet feeds run daily INCLUDING weekends, so they would need
   `frequency=DAILY`, not WEEKDAY. Do not copy the weekday setting across.

## Links
- Source decision and cadence evidence — [[wm-9dfnnt]]
- Full four-feed cadence table — [[wm-dfec2v]]
