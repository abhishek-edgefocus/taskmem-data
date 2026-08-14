---
id: wm-jr5bup
type: task
title: Revive the OpenRoad silver chain, then deprecate its datastores
status: active
size: xl
people: [Abhijeet, Frank]
tags: [openroad, datastores, dagster]
refs: [DEV-1486=https://linear.app/edge-focus/issue/DEV-1486/deprecate-openroad-datastores]
created: 2026-08-14T14:56:46Z
updated: 2026-08-14T14:56:55Z
source: claude-code
label: OpenRoad revive + deprecate
---

Container for the one genuinely sequential run of OpenRoad work. Created 2026-08-14 while
restructuring the memory into ordered threads: these three steps were siblings under the OpenRoad
project alongside half a dozen unrelated items, so the ordering — which is stated explicitly in
each of their bodies — was invisible in every view.

THE SEQUENCE, and why it is a real dependency and not a preference:

1. The silver chain is dead. `openroad_statement_sensor` is STOPPED in prod Dagster and has NEVER
   ticked; `statements_openroad` has exactly one run in its whole history, launched by hand from
   the UI on 2026-07-07. Silver stops at 2026-07-06 while bronze runs to 2026-08-11 — 36 as-of
   dates sitting unconsumed. The fix is an operational toggle, not a PR.
2. Deprecation has to wait for that, in the item's own words: running the file-registry backfill
   first "would park ~2,150 files in bronze and produce nothing in silver, because the consumer is
   dead."
3. The verified-differences file has to wait for both, because registering by-design differences
   against a table that is a month stale and ~1,070 dates short would paper over the first two
   problems rather than answer Frank's question.

NOT in this sequence, and deliberately so: salvaging the untracked comparison docs is urgent and
unblocked (the only copy is in a stale checkout on dpx), and the FULLY_PAID_DATE mapping, the
CMOP/BEP work and the model_requests ingestion are all independent OpenRoad work that stays
directly under the project.

## Next steps
- Check prod Dagster, then enable `openroad_statement_sensor` — but watch the first tick, since
  three other platform jobs currently fail on every sensor run.
- Render the order with `taskmem chain` on this item (the id is in the frontmatter above).

## Links
- DEV-1486 — https://linear.app/edge-focus/issue/DEV-1486/deprecate-openroad-datastores
- Prod Dagster — https://dagster-prod.edgefocuspartners.com
- Project: [[wm-su6q4d]]
- The broader sensor audit this came out of: [[wm-hjbt5a]]
