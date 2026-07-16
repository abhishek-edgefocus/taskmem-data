---
id: wm-r28p9n
type: task
title: Raise sshd MaxSessions on dpx to prevent VSCode Remote-SSH channel saturation
status: dropped
tags: [dpx, infra]
created: 2026-07-14T16:09:11Z
updated: 2026-07-16T17:52:18Z
source: claude-code
---

2026-07-14: Claude Code (and all remote extensions) stopped loading in VSCode on dpx. Root cause: ~/.ssh/config ControlMaster multiplexing + sshd default MaxSessions=10 on dpx — the shared SSH connection's channel table saturated, so VSCode's extension-host socket took 13-139s to open and missed its 60s ready deadline. Fixed by killing the control master (ssh -O exit dp). Follow-up: set MaxSessions 64 in /etc/ssh/sshd_config on dpx (needs sudo) so this can't recur.

## Log
- 2026-07-14T16:33Z [claude-code] Server-side changes are out of Abhishek's scope on dpx (shared host). Prevention must be client-side: remove ControlMaster sharing for the dp host, or give VSCode its own SSH config. Quick recovery if it recurs: ssh -O exit dp, then Reload Window.
- 2026-07-14T16:39Z [claude-code] RESOLVED client-side instead: removed ControlMaster/ControlPath/ControlPersist from the dp host block in ~/.ssh/config so VSCode Remote-SSH gets a dedicated connection. Verified: exthost9 on dpx activated 10 extensions incl. Anthropic.claude-code at 2026-07-14 16:39 UTC. If slow-socket symptoms ever return, check for anything re-multiplexing ssh to dpx.
- 2026-07-14T18:01Z [claude-code] TRUE ROOT CAUSE FOUND: AWS VPN Client tunnel (utun4) advertises MTU 1500; don't-fragment probes show full-size 1500-byte packets drop intermittently through the tunnel while <=1428-byte packets pass 100%. Bulk flows (VSCode extension-host init payload) stall tens of seconds in retransmission and miss the 60s ready deadline; small interactive traffic unaffected — which is why terminals/ssh always worked. Fix: sudo ifconfig utun4 mtu 1400 after each VPN connect (AWS VPN Client resets it). ControlMaster removal and stale-server cleanup earlier were useful hygiene but not the root cause.
- 2026-07-15T12:31Z [claude-code] Further findings 2026-07-15: mssfix directive in AWS VPN profiles is stripped by the AWS VPN Client (root-owned sanitized temp config). Mumbai vs Ohio endpoint makes no difference — packet drops are on Abhishek's local ISP leg (fragmented/oversize UDP), so bulk TCP through the tunnel crawls (~27KB/s incompressible) regardless of endpoint. Compressible data OK (~1MB/s effective; 3.6MB Claude transcript loads in ~28s via compressed ssh). No user-level fix exists without privileges. Escalation options: (a) Mac admin grants/runs sudo ifconfig utunN mtu 1400 after VPN connect; (b) dpx admin adds iptables -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1360 (fixes all VPN users). VSCode extension activates fine now; large session loads are just slow (~30s).
- 2026-07-15T12:40Z [claude-code] Deeper finding: throughput is direction-asymmetric — Mac→dpx 365KB/s, dpx→Mac 28KB/s per flow (parallel flows each get ~25KB/s, so it scales per-connection). MTU fix applied but not the limiter. Loss/policing is on the ISP downstream leg for sustained UDP, evening-correlated (onset ~18:38 IST both days; mornings fine). dpx TCP config normal (cubic, wscale on). Pending test: phone-hotspot A/B to convict home ISP. Durable fix candidates: TCP-transport Client VPN endpoint (IT), different uplink, ISP complaint. Sessions DO load now via compressed tunnel (~30s for 3.6MB); terminal claude unaffected.
- 2026-07-15T13:46Z [claude-code] archived during archive-feature verification
- 2026-07-16T17:52Z [claude-code] 2026-07-16 ~23:20 IST: recurred exactly as predicted after user's VSCode 1.129.0 update — new server downloaded fine server-side, exthost starts, 0 activations, tunnel at 25KB/s (evening throttle window). Confirmed not install-order related (user speculation): openLast-not-found is just the unactivated-extension symptom. Guidance: dpx extension mornings only until IT provides TCP-transport Client VPN endpoint; evenings → Coder workspace (TCP tunnel, set up 2026-07-15 with extension+CLI+creds) or dpx terminal claude --resume.
