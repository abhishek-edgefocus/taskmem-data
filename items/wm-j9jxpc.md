---
id: wm-j9jxpc
type: task
title: Check missing statement files for NorthPond and confirm in Kushagra's thread (before Friday dev call)
status: done
size: s
due: 2026-07-17
people: [Kushagra]
tags: [northpond]
links: [relates:wm-3tdn24, relates:wm-qu4cr7]
refs: [slack=https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1784107733166829?thread_ts=1784107733.166829&cid=C0B6M0AQKB5]
created: 2026-07-15T14:56:55Z
updated: 2026-07-16T20:19:40Z
source: intake-review
label: Kushagra missing files
---

Kushagra asked in #platform-data-owners (2026-07-15 14:58 IST) for each
platform owner to confirm in-thread once they've checked the missing
statement files for their platform — needed before the Friday dev call
(2026-07-17) so the list can be handed to ops. Status in-thread: Nakula
confirmed for Innovate (file missing, impact being assessed), Sanjali for
Prosper (missing but ignorable — old 2023 file, went into the
acknowledgment sheet), Abhijeet says he addressed all 5 of his and is
checking why the list hasn't refreshed. NorthPond (mine) is the one still
unconfirmed. Process per Kushagra: decide per file whether it affects the
platform or can be ignored; if it affects, start the conversation with the
platform cc'ing ops; either way record it in the acknowledgment sheet.

No blocker on Kushagra: the missing-files list IS in the thread — the
parent message's screenshot (F0BJACCTJU8) of the "Missing Platform Data"
dashboard. NorthPond row: statement_type=positions (NorthPond daily loan
tape), expected daily, 3 missing dates: 2024-08-09, 2024-08-28, and a
third truncated in the screenshot ("2024-0…" — read it off the dashboard).
Last checked 2026-07-12. All are old 2024 files, so likely the
Sanjali/Prosper pattern (ignorable → acknowledgment sheet), but verify.

## Next steps
1. Get the third missing date from the "Missing Platform Data" dashboard
   (screenshot truncates it).
2. For each of the 3 missing positions files: check whether it affects the
   platform or can be ignored. First rule out overlap with the
   already-closed missing-window alerts (ERROR-1524, wm-3tdn24) so nothing
   is double-reported.
3. Record the per-file outcome in the acknowledgment sheet (link not yet
   known — Sanjali used it on 2026-07-15, ask her or Kushagra if not
   findable).
4. Reply in Kushagra's thread confirming — before the Friday dev call.

## Links
- Source thread (Kushagra's ask): https://edgefocuspartners.slack.com/archives/C0B6M0AQKB5/p1784107733166829?thread_ts=1784107733.166829&cid=C0B6M0AQKB5
- Possibly-overlapping closed work: wm-3tdn24 / ERROR-1524 — https://linear.app/edge-focus/issue/ERROR-1524/missing-statement-filenorthpondpositionsnorthpond-loan-positions-4
- Related open investigation: wm-qu4cr7 / ERROR-1231 — https://linear.app/edge-focus/issue/ERROR-1231/northpond-issued-missing-gateway-responses-15-issued-northpond-loans

## Log
- 2026-07-15T14:56Z [intake-review] captured from Slack mention sweep (intake demo run); dedup anchor is the message permalink in refs
- 2026-07-15T15:08Z [intake-review] intake re-check: Kushagra's thread still has no NorthPond confirmation from Abhishek as of this evening; Nakula/Sanjali confirmed, Abhijeet checking his refresh
- 2026-07-15T15:12Z [intake-review] upgraded to pickup-ready standard (context, next steps, links)
- 2026-07-15T15:16Z [claude-code] Planned for tonight: unblock only — find/ask for the missing-files list in-thread; per-file analysis tomorrow
- 2026-07-15T15:23Z [claude-code] Corrected: no blocker on Kushagra — list is the dashboard screenshot in the thread parent (F0BJACCTJU8). NorthPond = 3 missing daily positions files (2024-08-09, 2024-08-28, +1 truncated). Rewrote next steps accordingly.
- 2026-07-15T19:36Z [claude-code] tagged needs-reply: Kushagra's @-mention in #platform-data-owners is still unanswered; Nakula/Sanjali/Abhijeet have replied
- 2026-07-16T11:23Z [claude-code] VERIFIED against PROD (read-only). Third truncated date = 2024-08-29. NorthPond gaps are exactly 3 single dates, all 2024: 08-09, 08-28, 08-29 (rule northpond_loan_positions, daily since 2024-07-10). Source of truth PROD.GOLD.STATEMENT_FILES_MISSING, refreshed 2026-07-15 16:05 PT (newer than Kushagra's 07-12 screenshot; prosper row already dropped off after Sanjali's ack, intex 5->4).
- 2026-07-16T11:23Z [claude-code] IMPACT = none / ignorable. Gaps are real at bronze+statement-rows layer (no file in bronze.statement_files under any status; no rows in silver.northpond_stmt_positions for the 3 dates). But silver.positions has FULL coverage: autofill_gaps() forward-fills, and AUTOFILL_LAST_SEEN_DATE proves it (08-09 carried from 08-08; 08-28 and 08-29 both carried from 08-27). Forward-fill of missing-file days is designed behaviour, not an accident. Portfolio was only 3-4 loans, all STATUS=current, 1-2 day carry -> immaterial. Verdict: ignorable -> acknowledgement sheet (the Sanjali/Prosper pattern).
- 2026-07-16T11:23Z [claude-code] Acknowledgement sheet FOUND (was listed as unknown): Google Sheet id 1gkWKElqMkgr7goxKS-s_L6xPNlAjGnr_3LhfgRMc7gY, tab 'Acknowledgements' — hardcoded as ACKNOWLEDGEMENT_SHEET_ID in edgefocus/monitoring/statement_file_acknowledgements.py. Columns: PLATFORM, STATEMENT_TYPE, ACK_START_DATE, ACK_END_DATE, ACKNOWLEDGED_BY, UPDATE_DATE, REASON. Single missing date => ACK_START_DATE == ACK_END_DATE, so northpond needs 3 rows.
- 2026-07-16T11:23Z [claude-code] No overlap with ERROR-1524/wm-3tdn24 double-reporting concern: ERROR-1524 IS the same 3 dates (same rule fingerprint), not a separate set. Nothing to de-dupe — acking the 3 dates resolves both.
- 2026-07-16T11:23Z [claude-code] Discovered: ERROR-1524 reopened 2026-07-15T16:04Z; wm-3tdn24 reopened from done. Stateless alerting means the ack sheet — not Linear state — is what actually silences it.
- 2026-07-16T11:24Z [claude-code] Analysis complete; remaining work is Abhishek-only (2 actions): (1) add 3 rows to the ack sheet, (2) reply in Kushagra's thread. Per Abhishek's instruction this run did NOT post to Slack. Cross-platform note for the Friday dev call: innovate transactions is ALSO missing 2024-08-29 (same date as northpond) — two platforms missing the same day points at a delivery/ingestion outage on 2024-08-29, not a platform-side issue; worth raising with Nakula/Kushagra rather than each owner acking it in isolation.
- 2026-07-16T12:43Z [claude-code] CORRECTION + hardened evidence (earlier 'immaterial' claim was asserted before it was fully checked; now actually verified). Autofill confirmed with real values: gap rows carry AUTOFILL_REASON='dropout', AUTOFILL_DAYS=1 for 08-09 (from 08-08) and AUTOFILL_DAYS=1,2 for 08-28/08-29 (both from 08-27). All 4 loans STATUS=current, DPD=0.
- 2026-07-16T12:43Z [claude-code] The REAL reason the 3 files are ignorable: the loan tape is a FULL-STATE DAILY SNAPSHOT (every outstanding loan every day), not an event/delta feed. So a missing day self-heals — the next tape carries complete true state — and no data is permanently lost. Verified economics are intact independently: a payment on OLV12562548 (37.98 prin + 12.02 int, PLATFORM_TRANSACTION_DATE=2024-08-08) and one on OLV12562550 (34.80 prin, PLATFORM_TRANSACTION_DATE=2024-08-09 — the missing day itself) BOTH landed in silver.transactions via the 2024-08-10 file. ITD/cashflows therefore correct.
- 2026-07-16T12:43Z [claude-code] Residual cost, stated honestly: the daily positions SNAPSHOT is stale on those 3 dates — forward-fill carries prior-day PRINCIPAL and ACCRUED_INTEREST, so e.g. 08-09 shows OLV12562548 principal 1050.00 when the 08-08 payment had already reduced it to 1012.02, and accrued interest is understated on every autofilled row. Impact bounded: 3-4 loans, ~10k total exposure, all current, Aug 2024, northpond funds are NOT in FUNDS_NEEDING_VALUATION (no manager marks). Ignorable stands, but it is 'snapshot stale for 3 old days', NOT 'no effect whatsoever'.
- 2026-07-16T13:06Z [claude-code] ANSWERED Abhishek's challenge: did we BUY loans on the gap dates? NO. This mattered because autofill only forward-fills loans with a PRIOR row — a loan purchased ON a missing date would be silently ABSENT (not stale), which autofill cannot mask. Verified via silver.transfers: the only Aug-2024 northpond purchases were 2024-08-01 (OLV12562549) and 2024-08-05 (OLV12562550). Nothing on 08-09, 08-28 or 08-29. So the missing tapes hide no purchase.
- 2026-07-16T13:06Z [claude-code] Applied Abhishek's before/after loan-set test on the RAW tape. 08-28/08-29 gap: 08-27 and 08-30 both show the identical 4 loans (547/548/549/550) -> clean, nothing happened across the gap. 08-09 gap: 08-08 has 3 loans, 08-10 has 4 (OLV12562550 added) -> set DIFFERS, but the missing file is NOT the cause: OLV12562550 was purchased 08-05 and is absent from the 08-06, 08-07 and 08-08 tapes too, which all DID arrive. It first appears 08-10 (5-day platform reporting lag). An arriving 08-09 tape would almost certainly not have contained it either.
- 2026-07-16T13:06Z [claude-code] Side-finding captured as wm-k3wt84 (inbox): NorthPond purchase -> first-appearance lag of 2-8 days in early portfolio, independent of missing files; may affect Fund Monitoring migration (wm-rgwdyu) if any panel reports point-in-time holdings.
- 2026-07-16T18:09Z [claude-code] DONE (2026-07-16, per Abhishek): both remaining actions completed — 3 rows added to the Acknowledgements tab (northpond/positions, 08-09, 08-28, 08-29, single-date so ACK_START_DATE==ACK_END_DATE) and confirmed in Kushagra's thread ahead of the 07-17 dev call. Verdict as analysed: ignorable (full-state daily snapshot self-heals; snapshot stale for 3 old 2024 days, ~10k exposure, all current).
- 2026-07-16T18:11Z [claude-code] Cross-platform 2024-08-29 note (innovate transactions missing the same date as northpond, logged 11:24Z as worth raising at the Friday dev call): DECLINED by Abhishek 2026-07-16 — deliberately not tracked and not being raised. Do not re-surface this as a missed commitment on future intake passes; it was considered and dropped, not overlooked.
- 2026-07-16T19:32Z [claude-code] Found prior analysis from a dpx session (b865d863, 2026-07-16): all 3 NorthPond missing positions dates identified and PROD-verified — 2024-08-09, 2024-08-28, 2024-08-29 (not just 2 as originally noted; third was truncated in the dashboard screenshot). Verdict: all ignorable — silver.positions has full coverage via autofill_gaps() forward-fill, portfolio was only 3-4 loans at the time. Bonus: acking these also resolves ERROR-1524 (same 3 dates); Innovate transactions also missing 2024-08-29, suggesting a platform-wide delivery outage that day, not NorthPond-specific. As of that session (last activity 2026-07-16 17:32 IST) the two remaining manual actions -- 3 rows in the acknowledgement sheet, reply in Kushagra's thread -- were still marked outstanding, no session evidence either was done since. I have no tool to read/write the Google Sheet (no MCP connector, WebFetch 401s on it, and the internal efp google_sheets.py service-account credential isn't provisioned on dpx -- gitignored, environment-specific). Cannot independently verify sheet state; asked Abhishek to confirm.
- 2026-07-16T19:52Z [claude-code] Closed. Acknowledgement sheet confirmed correct (2 rows covering all 3 dates: 2024-08-09, and 2024-08-28→2024-08-29 as a range), added by Abhishek 2026-07-16. Abhishek confirmed in Kushagra's thread. Reason recorded: daily loan tape never delivered by NorthPond, no purchases made those dates, loan tape before/after identical.
- 2026-07-16T20:19Z [claude-code] Verified directly against S3 (source of truth), per Abhishek's request: s3://efp-raw/statements/northpond/loan_tape/2024/08/ has no ffcnp_dailyloantape_* file for 08092024, 08282024, or 08292024 — confirms the files were genuinely never delivered by NorthPond (not just absent from a downstream table). Companion dailytransactiontape files DID land for all 3 dates as near-empty (190-byte) files, consistent with no purchases/transactions that day. Sheet entry wording confirmed accurate.
