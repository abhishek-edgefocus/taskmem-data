---
id: wm-abqg3u
type: question
title: Ask #transfer-data which purchase categories EDGEX 2026-1NN actually includes (fl / ff / td / secondary)
status: next
size: xs
people: [Abhijeet, Dustin, Trishit]
tags: [northpond, edgex, transfers]
links: [relates:wm-gj5tkx, relates:wm-4sxy5d, parent:wm-4sxy5d]
created: 2026-08-14T13:53:27Z
updated: 2026-08-14T20:18:44Z
source: claude-code
effort: ~15m
label: EDGEX purchase categories
---

Abhijeet told Abhishek to take this to #transfer-data on 2026-08-13 01:39 IST ("northpond che kahi
yenar hote loans secondary, ask on #transfer-data to understand"). Abhishek joined the channel a
minute later, at 01:40, and never posted the question. It is still open.

WHY IT MATTERS. Nate said in the DM on 2026-08-12 that "various northpond and oliv loans may end
up in the edgex securitization (i.e. the logic for the investor is not static)" and, separately,
"I know we will sell some of these loans that are currently northpond or oliv or efhyf to edgex,
but I don't have the ability to actually list which ones in any systematic fashion." Abhishek's
own reading was that EDGEX NorthPond was meant to be first-look only, and he then found internally
that secondary purchases are expected too ("PS: I just checked internally and got to know we are
expecting some secondary purchases"). Abhijeet's answer was that in general there are no
restrictions on which loans can come in.

So the ingestion-side rule Abhishek settled with Nate — the issuance file's `current_investor`
flips to edgex20261NN on the day of transfer, `intended_investor` stays as-is — is the mechanism,
but nobody has confirmed the population it applies to. If secondary and TD purchases are in scope,
the fund-split and at-purchase logic has to cope with loans that already have a northpond/oliv/
efhyf position history, not just fresh first-look originations.

## Next steps
- Post in #transfer-data (C0AUZU3HM60): which purchase categories does EDGEX 2026-1NN take —
  first-look (fl), forward-flow (ff), TD, secondary? Tag Dustin and Trishit, who post the
  transfer files there.
- Feed the answer back into how transfers and at-purchase fields are derived for the EDGEX fund.

## Links
- Channel: https://edgefocuspartners.slack.com/archives/C0AUZU3HM60
- Abhijeet's steer (DM): https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1786483011826879 (same DM, 2026-08-13 01:39 IST)
- Nate on non-static investor logic: https://edgefocuspartners.slack.com/archives/D0BAD46CT27/p1786559018138169
- Related feed work: [[wm-gj5tkx]]

## Log
- 2026-08-14T13:53Z [claude-code] Created 2026-08-14 during the intake sweep, from the Abhijeet DM of 2026-08-13 plus Nate's 2026-08-12 warning that the investor logic is not static. Nobody has been asked yet.

Fix to one link in the body above: the URL given for Abhijeet's steer (…/p1786483011826879) is his 2026-08-12 02:46 IST message in that DM, not the 01:39 IST line quoted — I did not have a permalink for that one. Right channel (D0B2A3WSJ5N), wrong message; scroll down from it to 2026-08-13 01:39.
- 2026-08-14T20:18Z [claude-code] First hard number on the population question, from the corrected Nelnet loan tape (2026-08-15): 218 of 392 loans carry current_investor_number=INV103, but only 113 distinct loans have ever appeared on a live purchase file (2026-08-11..08-14). All 113 purchased loans are tagged INV103 - the sources agree on the purchased set - leaving 105 tagged with no purchase event, disbursed 2026-08-01..08-13. So loans are reaching EDGEX status without a purchase file, or the tape tags intent rather than ownership. [[wm-uxwcxn]] asks Nate which. Whichever it is, the #transfer-data question stands.
