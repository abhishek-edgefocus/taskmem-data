---
id: wm-5qpdn3
type: task
title: Experian credit pull: Sentry EFP-ERRORS-AW masks the real error (non-200 body discarded)
status: next
tags: [oncall, northpond, experian]
links: [parent:wm-3y3ckv]
created: 2026-07-16T06:54:43Z
updated: 2026-07-16T06:54:49Z
source: claude-code
estimate: <1h
---

Debugged 2026-07-16 (investigation only, no code changes).

Sentry alert "Server Error: Experian Credit Pull Failed: Failed to pull Experian credit report: Missing: credit profile, Clarity report" (EFP-ERRORS-AW, sentry issue 7125718855) is a CATCH-ALL, not a diagnosis.

Path: northpond_loan_fl_channel.py ~652 raises PlatformServerErrorException when check_response.is_success=False AND no missing_features. That state comes from credit_pulled_channel.py::_check_incomplete_experian_pull "not pull_success" branch, which fires whenever the credit-report POST is non-200. It then probes the ERROR ENVELOPE for creditProfile/clarityReport keys, finds neither, and reports "Missing: credit profile, Clarity report".

The real cause sits in experian_response["errors"][*]["message"] and is DISCARDED. That is why this has been chased and marked "transient"/resolved 3x (May 8, Jun 5, Jul 13) without a root cause.

Evidence (CloudWatch northpond_loan_fl/production/gateway, 7d):
- credit-report POSTs: 4827x200, 6x400, 2x401 -> ~8 non-200 = the ~1/day Sentry alert. Sentry 83->96 events since Jun 30 is consistent.
- format_experian_request is a straight pass-through (selects consumerPii/requestor/permissiblePurpose/addOns/customOptions, no sanitization), so the 400s are most likely per-application bad input from Oliv/NorthPond. Matches Nate's May 8 note about adding "data sanitization on the Oliv side".
- The 2x401 on the POST: token expiry check in handler.py has no safety margin (`if bearer_token is None or time.time() >= expires_at`), and a 401 on the POST does NOT invalidate the token or retry. Token TTL 1800s, ~2 worker processes.

SEPARATE, ALREADY RESOLVED: Kabeer's 07-13 OAuth 401 "Your account is in invalid state" (user edgefocus_api). Token 401s by day: 07-09..07-11 = 0, 07-12 = 32, 07-13 = 247 (vs 58 ok), 07-14/15/16 = 0. Account-state issue at Experian, fixed after Kabeer escalated to Nate. Not today's alert.

Suggested (NOT implemented): surface experian_response["errors"] in error_msg so the alert names the real failure; consider a token refresh margin + single 401-retry.
