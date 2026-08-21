---
id: wm-85vvgw
type: correction
title: wm-te4cr2 is filed under ERROR-1626, but that ticket is a different (already Done) defect
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-te4cr2]
created: 2026-08-21T14:06:04Z
updated: 2026-08-21T14:06:04Z
source: linear-agent
label: wm-te4cr2 is filed under ERROR-1626
---

WHAT WE HAD: wm-te4cr2 titled 'ERROR-1626: northpond_exp_predictions fails every run — .efp_toplevel missing from the Dagster image', p1, status next.

WHAT IS TRUE (verified 2026-08-21 via mcp linear list_issues): ERROR-1626 is 'statements_northpond: failed — Steps failed: [northpond_transfers]', team Errors, priority Low, marked **Done** 2026-08-19T13:28Z. It has nothing to do with northpond_exp_predictions or the .efp_toplevel marker.

The root-cause analysis in wm-te4cr2's body still stands on its own evidence — orchestration/Dockerfile does a selective COPY that omits the .efp_toplevel marker, so Files.__init__ walks to / and asserts during model-spec resolution, confirmed from S3 compute logs on both the first (16c38465) and latest (8fa70376) failures. The defect is real and the asset has never once succeeded in prod.

WHY IT MATTERS: it has NO Linear ticket at all. Anyone checking ERROR-1626 sees Done and concludes the work is finished. Needs a new Errors ticket filed, and wm-te4cr2's title/refs repointed at it.

HOW IT SLIPPED: likely a mis-transcribed ticket number when the item was created 2026-08-10 — both are northpond Dagster failures surfaced through Sentry, so the ids were easy to cross.

## Environment
- taskmem: 1354261
- reported by: linear-agent
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-21T14:06:04Z
- corrected item: wm-te4cr2
