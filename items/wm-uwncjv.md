---
id: wm-uwncjv
type: task
title: Add EF Alpha + EFHYF to the Fund Performance Monitoring dashboard (DEV-1715, DEV-1716) — due 2026-09-29
status: active
priority: p2
size: l
due: 2026-09-29
people: [abhijeet]
tags: [northpond, grafana, fund-monitoring, demise-datastores, linear]
links: [related:wm-hz3hm9, parent:wm-j523sq]
refs: [DEV-1715=https://linear.app/edge-focus/issue/DEV-1715/add-ef-alpha-to-fund-performance-monitoring, DEV-1716=https://linear.app/edge-focus/issue/DEV-1716/add-efhyf-to-fund-performance-monitoring, dm=https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1788968937117249]
created: 2026-09-11T14:26:11Z
updated: 2026-09-21T12:44:45Z
source: slack DM D0B2A3WSJ5N + Linear
label: EF Alpha EFHYF fund monitoring
next: DEV-1716 plan: 1 snapshot rewrite on copy (per-platform latest) + re-run 164 queries; 2 FUND_NAME_TO_KEY one-line PR (draft) → merge → confirm Annualized Net Return renders; 3 cross-check UPB/loan count/DPD vs legacy datastore EFHYF dashboard for same date; 4 decide warehouse/PA rows (leave empty, Castlelake precedent) + flag POSITIONS_DAILY tail dip as separate item; 5 Abhijeet review of copy; 6 promote to prod FPM (fund var + rewritten panels) and confirm JV funds unchanged; 7 Linear DEV-1716 done w/ link, then repeat for EF Alpha DEV-1715
---

Two Linear tickets Abhijeet filed 2026-09-01 under the "Demise datastores" project, milestone "Port old dashboards to snowflake": add the EF Alpha fund and the EFHYF fund to the Fund Performance Monitoring dashboard and validate what each shows. Both are marked "a blocker for demising datastores" and both block DEV-1031 (Ingestion of roll rates into edgefocus/). Branch names Linear reserved: abhishek/dev-1715-… and abhishek/dev-1716-….

Deadline was negotiated in the Abhijeet DM on 2026-09-09 (in Marathi): Abhijeet proposed 25 Sept; Abhishek said he is likely on leave on the 25th (maybe before too) and asked for Tuesday the 29th; Abhijeet set both tickets to 2026-09-29 and added "don't start at the very end, this is not work that finishes in a day or two". Abhishek: "yes, will mostly start from Monday" — i.e. 2026-09-14. So the start date is itself a commitment (see the linked reminder).

Prior art worth reusing: the NorthPond Fund Monitoring migration (wm-rgwdyu, DEV-1395) already ported NorthPond panels to Snowflake and matched the old gold numbers for efhyf; wm-hz3hm9 records that efhyf (Evergreen) has no FUND_KEY in the FPM JV-keyed fund-returns query, which will bite here.

## Next steps
1. Open DEV-1715 and DEV-1716 and read the description + milestone; move both to In Progress on 2026-09-14.
2. Open the Fund Performance Monitoring dashboard (folder dfomia5rnkvlsd, uid ffdec6db) and list how a fund gets added (fund variable, FUND_NAME_TO_KEY, silver.fund_returns sheet) — check wm-hz3hm9 first for the efhyf FUND_KEY gap.
3. Add EFHYF first (NorthPond, data already validated in wm-rgwdyu), then EF Alpha; validate each fund's panels against the legacy datastore dashboard numbers.
4. Verify panels through /api/ds/query as GRAFANA_READER, not by running the SQL yourself.

## Links
- DEV-1715 https://linear.app/edge-focus/issue/DEV-1715/add-ef-alpha-to-fund-performance-monitoring
- DEV-1716 https://linear.app/edge-focus/issue/DEV-1716/add-efhyf-to-fund-performance-monitoring
- Deadline negotiation (Abhijeet DM) https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1788968937117249
- Related: wm-rgwdyu (NorthPond FPM migration, done), wm-hz3hm9 (efhyf FUND_KEY gap), wm-j523sq (NorthPond Data Ingestion project)

## Log
- 2026-09-11T14:26Z [claude-code] Captured in the 2026-09-11 sync from the Abhijeet DM of 2026-09-09 21:18-22:21 IST ('Hya donhi la due date takaychi ahe' → 29th set) and Linear (both tickets dueDate 2026-09-29, assigned to Abhishek, project Demise datastores, blocking DEV-1031).
- 2026-09-15T14:24Z [claude-code] 2026-09-15 started DEV-1716 (EFHYF first). Prod FPM is uid b7c89f53-932d-4495-b8d9-04a289fff3eb (folder Fund Monitoring dfomia5rnkvlsd, v17, last edit kushagra 2026-09-04) — the ffdec6db uid in earlier notes is stale. Verbatim copy created at https://grafana.edgefocuspartners.com/d/dev1716-fpm-efhyf in Testing Dashboards/Devs/Abhishek (ffmmyvk05io74f); prod untouched (still v17). Copy v2: added 'EFHYF : efhyf' to the fund custom variable (castlelake_auto precedent). Findings: efhyf is a FUND value in every fund-keyed table (SILVER.POSITIONS 2.1B rows across 9 platforms, lc = 1.99B — perf risk on the 55 SILVER.POSITIONS panels); no warehouse for efhyf → ~31 warehouse/PA panels structurally empty (same as castlelake); FUND_RETURNS FUND_KEY still NULL for EFHYF (castlelake_auto DID get FUND_KEY='castlelake_auto' as 'Joint Venture'). Snapshot ~/fpm_prod_snapshot.json + panel run results ~/dev1716_efhyf_panel_results.json on dpx.
- 2026-09-15T14:30Z [claude-code] Panel run (164 targets, fund=efhyf, platform=All, as_of=2026-09-15, 30d range) via /api/ds/query: 105 OK / 34 EMPTY / 25 warehouse-var N/A / 0 errors / max 29s (44 targets >10s). CRUX for a multi-platform fund: 55 SILVER.POSITIONS panels pin AS_OF_DATE = MAX(AS_OF_DATE) WHERE FUND=efhyf → today only anchored/northpond/upgrade had landed, so lc (700K loans)/upstart/marlette/prosper/openroad/innovate silently vanish from every current-book panel. JV funds never hit this (one platform). Needs a per-platform-latest (or common-date) snapshot rewrite before EFHYF numbers can be trusted; same will bite EF Alpha. Annualized Net Return (2 panels) empty = FUND_KEY NULL; sanctioned fix per fund_returns.py comment is a one-line PR adding 'Edge Focus High Yield Fund, LP': 'efhyf' to FUND_NAME_TO_KEY (castlelake_auto already went this route for DEV-1669) — resolves wm-hz3hm9's worry, FUND_KEY is documented as a dashboard key not a JV flag. Realized-DPD B_SF refs + CMOP refs empty for every fund (30d default range / curr_mod not selected) — not EFHYF issues. Fee/ACH/home-owner/income-verified/mgr-mark attribute panels empty = columns not populated for efhyf platforms (ACH only prosper, MGR_MARK_FRAC only 72 lc + 151 upgrade rows).
- 2026-09-15T14:32Z [claude-code-critic] 2026-09-15 critic check: verified via Grafana API — prod FPM still v17 (kushagra 2026-09-04), copy dev1716-fpm-efhyf is v2 in Testing Dashboards/Devs/Abhishek with efhyf added to $fund. Decision handed to Abhishek: approve per-platform-latest rewrite (QUALIFY ROW_NUMBER over PLATFORM) on the copy's SILVER.POSITIONS panels — identical for single-platform JV funds so promotable; leave warehouse/PA rows empty (Castlelake precedent); open the one-line FUND_NAME_TO_KEY PR. Caveat for the session: same partial-landing problem shows as a tail dip on GOLD.POSITIONS_DAILY timeseries (no 'all' rows exist for any fund there) — the rewrite does not fix those; and the ticket's 'validate' step still needs one number cross-checked against the legacy datastore EFHYF dashboard.
- 2026-09-16T14:18Z [claude-code-critic] 2026-09-16 Abhishek confirmed: EFHYF has no warehouse facility — warehouse/PA sections stay blank (Castlelake precedent); macq_wh2 question closed, not EFHYF's. Step 4 of the DEV-1716 plan decided.
- 2026-09-21T12:08Z [claude-code] 2026-09-21: copy v3 — view_as_of_date variable now = latest AS_OF_DATE in GOLD.POSITIONS_DAILY on which COUNT(DISTINCT PLATFORM) equals the fund's distinct-platform count over the last 30 days (COALESCE to plain MAX for funds with no rows in window). Verified via /api/ds/query: unchanged for all 6 existing options (sofi/prosper/castlelake 09-20, happymoney 09-19, marlette_hyp/hyp_2 09-18); efhyf 09-20→09-16 (LC lags, last 9-platform day); efalpha + paradigm1 also →09-16. Re-ran 164 targets: 87 OK / 52 EMPTY / 25 warehouse N/A / 0 errors / max 29s. Current-book panels now cover all platforms (TOTAL_PRINCIPAL 2.60M→7.43M, TOTAL_EXPOSURE 2.71M→7.38M). The 18 OK→EMPTY flips are NOT the variable: they are the 28 predicted-cashflow panels whose gold table is now empty in prod (see the new p1 bug item). Marlette silver rows also vanished in prod.
- 2026-09-21T12:44Z [claude-code-critic] 2026-09-21 step 1 done (copy v3, view_as_of_date = last complete date, verified). Abhishek: ignore the prod incident (wm-ugetkj); ticket scope is only adding EFHYF. Next: step 2 FUND_NAME_TO_KEY draft PR; step 3 legacy cross-check when data allows.
