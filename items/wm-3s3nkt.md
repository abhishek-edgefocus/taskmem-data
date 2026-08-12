---
id: wm-3s3nkt
type: followup
title: Confirm to Nate the exact issuance-V2 string values: fund name (underscore in EF 2026_1N) + loan_servicer values
status: next
priority: p1
size: xs
due: 2026-08-12
people: [Nate]
tags: [northpond, edgex, needs-reply]
created: 2026-08-12T16:36:50Z
updated: 2026-08-12T16:36:53Z
source: claude-code
---

Owed to Nate by end of day 2026-08-12, from the Oliv-EF integration call (transcript in ~/Downloads/Cleaned_Oliv_EF_Integration_Transcript.md).

Nate is adding two columns to the issuance V2 file and asked Abhishek to confirm the exact strings so he can deploy in time for TOMORROW'S file:
1. 'current or intended investor' — Nate's proposed values include Edge Focus high-yield fund, EF 2026 1N, North Pond, Oliv, Macquarie. Abhishek said he is fine with all of them EXCEPT the EDGEX one, where he wants an underscore between 2026 and 1N. Nate has a strong preference for lowercase snake_case and said he will oblige whatever we ask.
2. 'loan_servicer' — FCC vs Nelnet, so we stop having to infer the servicer from which servicing file a loan appears in.

Nate: 'if you let me know by the end of today... my goal would be to get it deployed so that your issuance v2 file tomorrow has these.' Abhishek: 'I will let you know shortly. I'll ping you on this.' Not yet sent.

Pick the strings against the existing internal fund mapping so we do not need a translation layer — our current fund values include efhyf and edgex20261NN. Note Abhishek told Nate we can map whatever string he sends to an internal value, so this is a convenience decision, not a blocking one — but it is a same-day commitment.

Investor values (INV103 etc) were explicitly DROPPED from this ask: they are collateral/buyback buckets, not investors, and we can get them off the loan tape. See [[wm-gj5tkx]].
