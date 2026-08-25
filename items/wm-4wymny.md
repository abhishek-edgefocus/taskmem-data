---
id: wm-4wymny
type: task
title: Rework the AI vendor spend dashboard per Frank + Scott's 2026-08-18 review
status: next
priority: normal
size: half-day
people: [Frank, Scott]
tags: [ai-billing, ramp, dev-970, grafana]
links: [parent:wm-r45vp3, blocks:wm-399bwq]
created: 2026-08-24T13:35:45Z
updated: 2026-08-25T15:53:33Z
source: meeting-2026-08-18
next: Judge on screen whether Spend per User reads well now Cursor is back in -- Frank is ~62% of it (team card sits on him), so his bar may dominate; fallback is a top-10 user cap. Then: totals on top of bars (decide labelled total bar vs per-segment labels); review item 1 'AI usage' dashboard. Housekeeping: revoke GRAFANA_READER on DEV_ABHISHEK.SILVER (unused post-prod switch); chase Kabeer re 403 on Agents Usage dashboard e907d00b.
---

Feedback from the 2026-08-18 "AI Spend Monitoring Dashboard - Review" call with Frank and Scott.
Full notes: `~/meeting-notes.md` (raw transcript in `~/meeting-transcripts.md`).
Dashboard is f0cd399b-fe80-4bb2-82b7-a5a3fc092440.

1. **Split into two dashboards** — AI usage (Kabeer's agent section) and AI spend. Frank's rule: every chart on a page must respond to that page's dropdowns, otherwise split the page. This supersedes the earlier one-master-dashboard decision and removes the need for the dashboardNewLayouts/tabs toggle.
2. **Stop the 3-month moving average at the last COMPLETE month** — including the partial month fakes a downward trend.
3. **Add a month-to-date pace marker** on the current-month bar: 3-month average of spend through the same day-of-month, as a dot/diamond/dotted overlay. Explicitly NOT a full-month projection.
4. **Delete the eight stat tiles at the top.** Transaction counts are meaningless, all-time spend is questionable, and the current-vs-average delta is misleading (always negative until month end).
5. **Print the stacked-bar total on top of each bar**; keep the per-vendor breakdown in the hover.
6. **Remove week and day granularity — monthly only.** Weekly only means anything for Cursor; Anthropic bills on subscription anniversaries.
7. **Drop the top-5 largest-transaction tables and the per-vendor tables**; condense into the one chart.
8. **Add a spend-by-Ramp-cardholder pie chart**, not front and centre — its purpose is spotting someone who should move to the company/enterprise card. Open concern: 30–35 subscriptions may make it unreadable.
9. **Match the API Gateway Monitoring / SoFi look and feel** — rolling average as dots in the text/white colour.

Then book the 15–30 min follow-up with Frank (wm-399bwq).

## Log
- 2026-08-25T14:20Z [claude-code] Dashboard v88-v92. Frank's Slack asks implemented: blue notice strip / title tile / Last Updated cloned from API Gateway; 'Ramp Cardholder' label; titles Spend per Month / Spend per User / Spend by Vendor. Spend per User reworked -- vertical bars stacked by vendor, team-subscription (Cursor) exclusion dropped, orange SELECTED stripe removed, axis labels shortened to 'First L.', moved to full width. All three graphs now honour both the time range and the cardholder dropdown and agree on totals (July all = 7901.25; July Frank = 4883.11; 10-12 Mar = 1344.80). Exact ranges no longer round out to whole months. 3-month average + projection suppressed unless the range is whole months, so they cannot sit beside a partial bar.
- 2026-08-25T14:46Z [claude-code] v100: implemented Scott's month-to-date pace marker on panel 104 (review item 3). Verified his numbers against PROD first: anchor 2026-08-24, May/Jun/Jul 1-24 = 7446.70/9269.60/6278.38, avg 7664.89, Aug actual 6360.02 = 17.0% below pace -- all match. Adopted his design (anchor on MAX(AS_OF_DATE) not CURRENT_DATE; lone point; series named '3-mo pace (through day N)' to dodge the .*3-month average.* override regex; no displayName so the day number shows) but grafted onto the live query rather than pasting his wholesale -- his predates Frank's exact-range change and omits the projection. Repointed the projection's DAY(CURRENT_DATE()) at the anchor's CUT_DAY so the dotted line, band and marker all agree. Verified: pace holds at 7664.89 across now-1y/now-3M/Aug-only, absent when the range ends 6 months back, cardholder-filtered (Frank 5785.01), and the partial/complete test is right for 2026-08-31/02-28/01-31/03-31 (complete) and 08-24/03-30 (partial).
- 2026-08-25T15:53Z [claude-code] v103-107 on panel 104, from Abhishek testing odd time ranges. Rule is now: a bar means a whole month. Clipped months are not drawn (fixes the old 30-day/July-cutoff distortion); when no month in range is complete the panel blanks with a legend note. Wording corrected from 'shorter than a month' (false for a 51-day May 5-Jun 25 range) to 'No complete month in this range'. Single-month ranges rendered one panel-wide bar because bar width derives from the gap between x positions -- fixed by padding the month spine one month either side with NULL-valued positions. barAlignment set to 1 so a bar labelled May 26 occupies May instead of straddling the 1 May tick. Padding exposed a latent bug in the covered CTE: LEAST(LAST_DAY(M), ANCHOR) collapses to the anchor for a future month, so September counted as complete, drew a bar and bypassed the guard on a 7-day range -- now future months are never covered. Also confirmed the invisible-bar-overlay hack for bar totals is not viable: bar-chart categories are evenly spaced while a time axis is date-spaced, giving up to 86px drift against a 44px bar. Experiment dashboard left at uid c8baaca0-9a30-4bdc-aebb-bc16b406624d, delete when done.
