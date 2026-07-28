---
id: wm-9kvv8c
type: task
title: Confirm or kill: do Sentry EFP-ERRORS-AW events carry live applicant PII?
status: inbox
size: xs
tags: [northpond, api-health]
links: [parent:wm-3y3ckv]
created: 2026-07-28T17:38:52Z
updated: 2026-07-28T17:38:52Z
source: claude-code
label: Sentry PII check EFP-ERRORS-AW
---

Loose end carried out of [[wm-unzbpr]] when that item closed. An external reviewer reported that
Sentry issue EFP-ERRORS-AW (the Experian credit-pull 401s on the northpond get-offers path) captures
live applicant PII — SSN, DOB, name, address — in the request body attached to each event.

**This is unverified in both directions.** The Sentry MCP event view does not expose a request body,
so it could not be confirmed; but the breadcrumbs show `[Filtered]` on several fields, so scrubbing
is at least partly active. Neither "it leaks PII" nor "it is fine" is established.

If confirmed it is a data-handling issue that deserves its own ticket, entirely separate from the
401 auth bug (already filed as DEV-1478).

## Next steps
1. Open a recent EFP-ERRORS-AW event in the Sentry UI directly (not via MCP) and look at the
   Request section — the MCP surface is what blocked the check.
2. If PII is present, file a ticket for it and check whether the same capture path affects other
   platforms' get-offers errors, not just northpond.
3. If it is scrubbed, log that here and close — the claim then just needs retiring.

## Links
- Origin item: [[wm-unzbpr]]
- The separate, already-filed 401 bug: https://linear.app/edge-focus/issue/DEV-1478
- Sentry issue: https://edgefocus.sentry.io/issues/7125718855/
