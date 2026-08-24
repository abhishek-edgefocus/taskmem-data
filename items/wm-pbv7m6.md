---
id: wm-pbv7m6
type: bug
title: Current-date autofill rows in silver.positions anchor on a stale snapshot (AUTOFILL_DAYS overstated, values carried from too far back)
status: open
priority: normal
size: <1h
tags: [positions, autofill, data-quality, openroad, prosper]
links: [relates:wm-duhj7d, relates:wm-su6q4d]
created: 2026-08-24T12:33:49Z
updated: 2026-08-24T12:34:15Z
source: claude-code
---

Found 2026-08-24 while investigating why openroad started appearing in the daily
#dropout-loans-info report. Not openroad-specific and not urgent; the alert story
itself is on [[wm-duhj7d]].

## Symptom (PROD, measured 2026-08-24)
silver.positions holds a fully synthetic row set for the CURRENT date (no tape yet),
and those rows are anchored on a snapshot several days older than the newest real
data that exists:

| platform | as_of 2026-08-24 rows | AUTOFILL_LAST_SEEN_DATE | AUTOFILL_DAYS | newest real date |
|---|---|---|---|---|
| openroad | 15 dropout + 20 terminal | 2026-08-19 | 5 | 2026-08-23 |
| prosper  | 17,104 dropout          | 2026-08-20 | 4 | 2026-08-23 |
| upgrade  | 14,223 / 11,582 dropout | 08-23 / 08-22 | 1 / 2 | 2026-08-23 (correct) |

openroad's 08-24 rows should read last-seen 2026-08-23 / AUTOFILL_DAYS 1.

## Mechanism (inferred from code + row timestamps, NOT from a Dagster log)
positions_corrections.autofill Phase 2 Pass 2 reads the PREVIOUS day from
`target_table` (silver.positions), not from the temp table, and the target is not
rewritten until the end of the run. So on the run of 2026-08-24 03:49 the real rows
for 08-22/08-23 went into temp at 03:49:16 while the 08-24 fill at 03:49:43 still saw
the pre-run target -- i.e. yesterday's own autofilled 08-23 row, which carried
AUTOFILL_LAST_SEEN_DATE = 08-19 forward via
`COALESCE(prev.AUTOFILL_LAST_SEEN_DATE, prev.AS_OF_DATE)`. Once the real 08-22/08-23
rows overwrite the target, the 08-24 row keeps a last-seen that no longer matches
reality. Where the anchor differs, the CARRIED VALUES (principal, DPD, bands) also
come from the older snapshot, not just the counter.

## Impact
- Cosmetic on the dropout report itself (it counts rows, not days), but the
  Grafana "Missing Platform Data" board's 1-7d / 8-14d / 15-30d / 31+ buckets and
  MAX_AUTOFILL_DAYS are wrong for the current date.
- Real, if small, on values: today's synthetic row can carry balances several days
  stale on any platform whose tape lands a day late.
- Self-clears: the date stops being synthetic once its own tape lands.

## Where to look
edgefocus/transformations/silver/statement_rows/positions_corrections.py
(`autofill_positions`, Phase 1 spine + Phase 2 Pass 1/Pass 2). Confirming the
mechanism properly means reading the openroad_positions run log for
2026-08-24 03:49 PDT and checking the processing-date list.

## Links
- Investigation this fell out of: [[wm-duhj7d]]
- OpenRoad ingestion project: [[wm-su6q4d]]
