---
id: wm-k8ppvk
type: correction
title: Reported wm-ku5sen's stored description as current fact; Dagster prod shows the assets DID materialize
status: inbox
tags: [taskmem-bug, correction]
links: [relates:wm-ku5sen]
created: 2026-07-21T09:15:44Z
updated: 2026-07-21T09:18:09Z
source: claude-code
label: Reported wm-ku5sen's stored description
---

WHAT I REPORTED (2026-07-21 session): surfaced wm-ku5sen to Abhishek as 'p1, ~1 day, never materialized in prod, untouched' — presenting both the never-materialized claim and the untouched claim as current state.

WHAT IS ACTUALLY TRUE (verified read-only against https://dagster-prod.edgefocuspartners.com/graphql, latest materialization per asset):
  edgex20261NN_happymoney_cl  -> 2026-07-20 20:47 UTC
  edgex20261NN_northpond_cl   -> 2026-07-20 18:59 UTC
  edgex20261NN_marlette_cl    -> 2026-07-20 14:54 UTC
  edgex20261NN_prosper_cl     -> 2026-07-20 11:41 UTC
  edgex20261NN_upgrade_cl     -> 2026-07-16 11:01 UTC
  warehouse_thresholds        -> 2026-07-18 08:43 UTC
All five 2026-1NN CL assets have materialized, four of them on 2026-07-20 — the day before I called them 'never materialized' and 'untouched'. Abhishek had already run them.

ROOT CAUSE: I read the item's stored title/description and repeated it to the human as present-tense fact. The item was written 2026-07-17; the materializations ran 07-16 through 07-20, i.e. around and after it was written. A taskmem item records what was true WHEN WRITTEN — it is not a live view of the system. I never opened the system of record (Dagster) before asserting the state of the system.

This is the SECOND correction filed in the same session (see the 'to:me only' Slack correction). The shared generalization, which matters more than either instance: I asserted CURRENT state from a source that only stores PAST state, and skipped the authoritative system. For the Slack case the authoritative source was the sent-messages history; here it is Dagster. Any claim of the form 'X has not happened' / 'X is untouched' is a claim about the live world and must be checked against the live world, never inferred from an item's stored text or from the absence of a taskmem log entry.

FIX FOR FUTURE AGENTS:
1. Before reporting any item as not-done / never-ran / untouched, verify against the system that owns that fact — Dagster for materializations, Snowflake for row counts, Linear for ticket state, git/GitHub for merges, Slack sent-messages for replies. Stored item text is a lead, not evidence.
2. Age-check: if an item's factual claim predates the window you are reporting on, it is presumed STALE until re-verified. wm-ku5sen was written 07-17 and I was reporting on 07-20 -> 07-21; that gap alone should have forced a check.
3. When an item mixes several claims, verify them independently. Here 'never materialized' is now disproven, while 'zero rows' and 'missing eligible_loans/trigger_limits' are separate claims with separate evidence — disproving one does not close the item.
4. Dagster prod GraphQL is reachable read-only and unauthenticated from Abhishek's machine: POST https://dagster-prod.edgefocuspartners.com/graphql with {"query": ...}. The web UI is a React SPA so WebFetch returns only an empty shell — always use GraphQL. assetsOrError lists asset keys; assetOrError(assetKey:{path:[...]}){assetMaterializations(limit:1){timestamp metadataEntries{...}}} gives last-materialized time. This is a cheap check with no excuse for skipping it.

## Environment
- taskmem: d149e26
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-21T09:15:44Z
- corrected item: wm-ku5sen

## Log
- 2026-07-21T09:18Z [claude-code] SCOPE REFINEMENT from Abhishek, same session: 'I know stuff is verified over there. You need not reverify.' The fix recorded in this correction must NOT be read as a licence to re-check work the human has already confirmed. Correct boundary:
- VERIFY before ASSERTING a negative — 'never ran', 'untouched', 'not done', 'unanswered'. That was this correction's actual failure and the rule stands unchanged.
- DO NOT re-verify once the human has stated something is done or verified. Their word is the evidence of record; going and checking anyway wastes their time and reads as not trusting them. Log their confirmation as the evidence and move on.
The failure mode this guards against is an agent over-correcting into compulsive re-checking after being caught in a stale claim — which is its own way of being unhelpful.
