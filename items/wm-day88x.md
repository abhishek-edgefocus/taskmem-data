---
id: wm-day88x
type: task
title: Run rounds 2-3 of the taskmem agent-behavior eval and ship the fixes
status: done
tags: [taskmem]
created: 2026-07-15T18:09:33Z
updated: 2026-07-16T06:59:48Z
source: claude-code
---

Rounds 2 and 3 ran 2026-07-16 (sandboxed, WM_DIR-jailed, one sandbox per scenario; real memory verified untouched by a HEAD tripwire both rounds). Harness added an adversarial-verify stage: every grader failure was re-checked against the git diff, so false positives never drove a contract edit.

ROUND 2 (10 grounded scenarios, overall 9.14/10): capture 9.7, bodies 9.3, response 9.3, hygiene 9.1 — but updates 8.3, and the whole gap was ONE pattern: over-mutation on read-only asks (s1 'what's on my plate' silently rescheduled wm-drehnk and committed a stray drehnk-body.md scratch file; s2 delegate and s4 story rewrote bodies). Root cause was the unscoped 'thin body is always in scope to upgrade' touch rule from round 1. Fixed in commit 6446616: new 'When NOT to write (read-only asks)' section, scoped touch rule, delegate marked a read-only export, give-the-action rule reconciled, plus a disambiguation guard so the boundary can't suppress real intake.

ROUND 3 (regression, same 10 + s11 buried-commitment guard): the fix landed decisively — updates s1 2->10, s2 7->10, s4 7->10, with byte-level proof (HEAD == baseline, empty diff) and agents offering instead of acting ('Want me to move its scheduled date?'). No over-correction: s11 captured the Kushagra promise while leaving all read-only items pristine; s3 still captured both asks and correctly made no item for Rahul's FYI. Round 3's stricter rubric then surfaced defects round 2 missed, fixed in commit daeddfe — the important one being a real CLI bug, not a prompting issue.

Overall averages moved 9.14 -> 8.82, which is NOT a regression: round 3's rubrics were deliberately harsher (any mutation fails s2; a child sized l fails s8; doubled log tags fail). The trustworthy signal is the updates delta on the fix targets.

Rounds are paused per Abhishek after round 3; round-3's own fixes are therefore unvalidated — see the follow-up item.

## Next steps
(none — complete)

## Links
- Round-2 results: /private/tmp/claude-501/-Users-abhishek/088d1f15-3a94-4724-af92-ec8b8c72ceb9/tasks/wx483uo2p.output (session scratchpad — copy out if it should survive)
- Round-3 results: /private/tmp/claude-501/-Users-abhishek/088d1f15-3a94-4724-af92-ec8b8c72ceb9/tasks/wz0u6lk9h.output
- Harness scripts: scratchpad/eval-r2/eval-round2.js, scratchpad/eval-r3/eval-round3.js
- Commits: 6446616 (read-only boundary), daeddfe (CLI log preservation + round-3 fixes)

## Log
- 2026-07-16T06:59Z [claude-code] done: rounds 2-3 complete. R2 9.14/10 found one real defect (over-mutation on read-only asks); fixed in 6446616. R3 proved it landed (updates 2/7/7 -> 10/10/10, zero mutations, no over-correction on the s11 guard) and surfaced a CLI data-loss bug: set --body destroyed ## Log. Fixed in daeddfe; append-only now enforced by the CLI. Rounds paused after 3 per Abhishek.
