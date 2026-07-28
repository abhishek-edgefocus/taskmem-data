---
id: wm-gj5tkx
type: task
title: Ingest Oliv's Nelnet loan + transaction files (new servicer, replaces FCC feed; carries investor tag)
status: open
priority: p2
size: l
people: [Nate, Trishit]
tags: [northpond, edgex]
links: [parent:wm-j523sq, relates:wm-5z3pjt]
created: 2026-07-28T11:49:54Z
updated: 2026-07-28T11:49:57Z
source: claude-code
---

Raised by Nate Wong 2026-07-28 in the EDGEX 2026-1NN investor-mapping thread (group DM C0BJ1M304BU, parent ts 1785238591.530479), as point 3 of his proposal.

Oliv has moved servicer from FCC to Nelnet. They have not yet extended the Nelnet loan + transaction files to EF — "for no reason other than prioritization". These are the equivalent of the files we receive today sourced from FCC. Critically, the Nelnet LOAN file carries the investor tag, so this feed is what properly resolves INV103 (EDGEX Grantor Trust) vs INV105 (EDGEX Purchaser I) — see wm-5z3pjt.

Repo state verified 2026-07-28 (~/repos/efp master): nothing consumes Nelnet data. The only "nelnet" reference is configs/default_passwords.json:371, an OUTBOUND sftp block (hostname mft.nelnet.net, remote_directory "To_Nelnet/") unrelated to Oliv ingestion. No parsing rules, no bronze platform config, no silver transformations.

Open questions to settle before scoping:
- Do the Nelnet files REPLACE the current Oliv loan/transaction files or run alongside them? If a cutover, we need a dual-run window and a reconciliation before switching.
- What is the file format / schema, and does it differ from the current FCC-derived tapes?
- Delivery mechanism — same SFTP account as today, or new?
