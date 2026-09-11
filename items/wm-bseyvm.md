---
id: wm-bseyvm
type: followup
title: Review dependabot PR #6767 (gitpython 3.1.58→3.1.59 in northpond/experian endpoint) — Abhijeet CC'd you
status: next
size: xs
due: 2026-09-14
people: [abhijeet]
tags: [needs-reply, northpond, api-health, github]
links: [related:wm-vv3htk]
refs: [PR=https://github.com/edgefocus/efp/pull/6767]
created: 2026-09-11T14:26:11Z
updated: 2026-09-11T14:26:11Z
source: github PR #6767
label: gitpython bump northpond experian
---

Dependabot security bump of gitpython 3.1.58 → 3.1.59 in lib/efp/json_endpoints/platforms/api/northpond/experian (published 2026-08-10, 31 days old). Abhijeet approved on 2026-09-10 16:36Z: "Looks good! Also CC @abhishek-edgefocus for review". PR is open, not draft, no Linear ticket linked (the check is a nudge, not a blocker). One-line config change.

Merging it changes the northpond experian endpoint image, so it should ride along with the PII-hash deploy of the northpond APIs (wm-vv3htk) rather than trigger a separate deploy.

## Next steps
1. Open https://github.com/edgefocus/efp/pull/6767, approve or comment.
2. Merge together with / before the northpond API deploy in wm-vv3htk so one deploy carries both.

## Links
- PR https://github.com/edgefocus/efp/pull/6767
- Deploy item wm-vv3htk
