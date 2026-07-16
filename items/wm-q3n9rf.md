---
id: wm-q3n9rf
type: task
title: Experian OAuth connect: 0.5s connect timeout + IPv6 AAAA fallback mislabels blips as 'Network is unreachable'
status: open
created: 2026-07-16T07:05:03Z
updated: 2026-07-16T07:05:03Z
source: claude-code
---

Debugged 2026-07-16 (investigation only, no code changes). Root cause of today's two #errors alerts.

ALERTS (both fired 2026-07-16 11:52 IST, "First Seen: Just now"):
- EFP-ERRORS-1J8 (sentry 7614572960) "Error getting OAuth token: ... NewConnectionError ... [Errno 101] Network is unreachable"  <- handler.py:230
- EFP-ERRORS-1J9 (sentry 7614573058) "[1784182938899396049] Error contacting Experian servers: ..."                              <- northpond_loan_fl_channel.py:1068
These are ONE event double-reported (same exception, logged twice, 06:22:20.016 and 06:22:20.023 UTC).

VERDICT: Experian was NOT unreachable. The message is a lie produced by an IPv6 fallback artifact.

MECHANISM (reproduced exactly on dpx):
1. us-api.experian.com is behind Imperva and publishes BOTH A (45.60.44.182) and AAAA (2a02:e980:dd::b6).
2. Hosts have NO IPv6 default route, but urllib3 HAS_IPV6=True -> allowed_gai_family()=AF_UNSPEC, so getaddrinfo returns IPv4 then IPv6.
3. handler.py:195 uses timeout=(0.5, 3.0) -- a 500ms CONNECT timeout. A transient latency/packet-loss blip pushes the IPv4 connect past 500ms.
4. socket.create_connection then tries the IPv6 address, which fails INSTANTLY with ENETUNREACH (measured 0.1ms, no route).
5. create_connection overwrites `err` per address and raises the LAST error -> the IPv6 ENETUNREACH MASKS the real IPv4 connect timeout.
6. urllib3 wraps it as NewConnectionError "Failed to establish a new connection: [Errno 101] Network is unreachable".

TIMING PROOF (this is decisive):
- observed attempt 1: 06:22:18.927834 -> 06:22:19.510276 = 582ms
- observed attempt 2:                 -> 06:22:20.016315 = 506ms
- local reproduction (fake gai [blackhole-IPv4, real-IPv6], timeout=0.5): elapsed 501ms, raised "OSError: [Errno 101] Network is unreachable"
A GENUINE loss of route would fail IPv4 instantly too (~0.1ms), giving ~1ms total, NOT ~500ms. The ~500ms elapsed proves the IPv4 socket was sitting in a connect timeout. Baseline IPv4 connect is ~12ms (min 10 / median 12 / max 16 over 12 samples), i.e. ~40x under the timeout.

BLAST RADIUS: 1 application (transaction 1784182938899396049). NorthPond got a NorthPondResponse_Error. Fully recovered - next token at 06:28:29 = 200, all POSTs 200 since. Only ONE ENETUNREACH in the last 30 days. No other gateway (openroad/prosper/happymoney/sofi/northpond-model) saw anything at 06:22.

CONTRIBUTING: session adapter is Retry(total=1, backoff_factor=0) -> 2 attempts ~1.1s apart with no backoff, so a ~1s blip is a hard user-visible failure.

SUGGESTED (NOT implemented):
- Raise the OAuth connect timeout from 0.5s to ~3-5s (12ms baseline; 0.5s has no headroom). Credit-report POST uses the same 0.5s connect.
- Add backoff_factor so the retry doesn't land inside the same blip.
- Optionally force AF_INET (no IPv6 route exists) so the misleading ENETUNREACH stops masking the true error.

NOTE: OAuth usernames in prod logs are `northpond_api2` and `cashflow_api`, NOT `edgefocus_api` (the account Kabeer cited on 07-13). Worth confirming which account Kabeer's 401 issue actually referred to.
