---
id: wm-wn8wbk
type: task
title: Confirm expected CNL on Oliv HYF loans contributed to EDGEX 2026-1NN (vs broader deal)
status: done
created: 2026-07-21T07:16:39Z
updated: 2026-07-21T12:32:03Z
source: claude-code
---

Dustin Redding asked in #edgex-tech thread (parent 2026-07-17 "For EDGEX 2026-1NN we'd like to contribute the following loans...", reply 2026-07-21 09:07 IST, ts 1784605054.255859):

> The attached files have been filtered to exclude loans: not current or >0 dpd; bankrupt borrowers; hardship borrowers. The EDGEX investor would like to know the CNL on these loans vs the broader deal. Can you both please confirm the expected CNL for these loans?

Addressed to both Abhishek (Oliv/HYF slice) and Gobind (Upgrade/Alpha slice).

Attachments on that reply:
- Oliv_HYF_To_EDGEX_2026-1NN.xlsx (F0BJG3D1UKV) <- Abhishek's slice
- Upgrade_Alpha_To_EDGEX_2026-1NN.xlsx (F0BJLAXLFFY) <- Gobind's slice

Background: on 2026-07-17 Abhishek posted OLIV_LOAN_TAPE_LATEST.csv (F0BHMUCUURM) into the same thread; Dustin has since filtered it. ~$300K of eligible Oliv loans from High Yield Fund; deal target close 7/28/26.

Deliverable: expected CNL (cumulative net loss) for the filtered Oliv loan set, and a comparison against the broader EDGEX 2026-1NN pool CNL. Likely sourced from our predicted cashflows for these loan ids.

Thread: https://edgefocuspartners.slack.com/archives/C08J572GQBE/p1784605054255859?thread_ts=1784236381.624749&cid=C08J572GQBE

## Log
- 2026-07-21T09:07Z [claude-code] ANALYSIS DONE (2026-07-21, claude-code, on dpx ~/repos-2/efp, PROD_READONLY Snowflake).

Filtered tape Oliv_HYF_To_EDGEX_2026-1NN.xlsx: 223 loans, $434,066 current principal (NOT ~$300K as Dustin's 07-17 estimate said), $727,731 original balance, pool factor 0.596. All 36-mo term, WA int rate 26.43%, WA remaining term 17.75 (WA MOB ~16-18). All current / 0 dpd / no bankruptcy / no hardship as of tape date 2026-07-15. 11 states, GA 32.3% + IL 21.0% of principal. EF grade: E4 70.0%, E3 15.9%, E5 11.0%, E2 3.1%.

Data available: silver.PREDICTED_CASHFLOWS has at_orig predictions for all 223 (platform='northpond', efp_id='northpond_'+POSITION_ID). NO curr_mod / best_est rows exist for northpond at all (only at_orig, 788 ids) -- see wm-79k8df. Canonical CNL = cumsum(chargeoff - recovery) / BOP_PRIN at first mob of window (lib/efp/modeling/data_processing/foms/loss.py dollar_loss/cumulative_dollar_loss; registered in lib/efp/mob_curves_helpers.py:50).

At-orig predicted lifetime CNL (denominator = original balance):
- contributed 223-loan slice: 19.30% (CGL 21.21%)
- ALL Oliv w/ preds (788):    19.92%
- Oliv NOT contributed (565): 20.17%
=> on a like-for-like at-origination basis the slice is only ~60-90bps better than the rest of the book.
Curve for the slice: CNL@12 9.55%, @18 14.87%, @24 17.72%, @36 19.30%. 77% of lifetime CNL was expected in MOB 1-18 (already elapsed); 23% in MOB 19-36.

BLOCKER on giving a forward number: the at-orig model is badly miscalibrated for Oliv. Realized vs at-orig predicted CGL on the whole book (715 loans, positions as of 2026-07-20, vintage-aligned): MOB 6 2.68% vs 1.27% (1.8-2.1x), MOB 9 10.20% vs 5.57%, MOB 12 18.64% vs 10.05%, MOB 15 24.94% vs 13.65%, MOB 18 23.58% vs 16.39%. Book has realized 20.27% gross loss ($511,853 CO principal / $2,525,495 orig, 156 of 715 charged off) at WA MOB only 14.6, vs 21.21% predicted for FULL 36-month life. Also actual surviving balance is 1.7x model-predicted for the whole book (2.19x for the clean slice) -- selection + miscalibration mixed.
=> do NOT quote naive "at-orig tail / current balance" = 6.87%; that divides a survival-probability-weighted dollar loss by an unweighted balance. Rate-consistent version (model remaining loss / model surviving balance) = 15.03%, i.e. ~$65K on the $434K. Neither is defensible to an investor without curr_mod/best_est.

ALSO FLAG TO DUSTIN: 2 of the 223 have gone delinquent since the 07-15 tape date -- OLV12562758 (2 dpd, $2,879.33) and OLV12562639 (8 dpd, $3,322.59), both loanstatus InGracePeriod as of 2026-07-20. Both would fail his own ">0 dpd" exclusion.

AMBIGUITY to resolve with Dustin before answering: (a) lifetime-from-origination CNL vs remaining-from-purchase CNL; (b) what "the broader deal" means -- full EDGEX 2026-1NN pool across all platforms, or the rest of the Oliv HYF book. Note the 2026-1NN warehouse still has no CNL trigger implemented (edgefocus/warehouses/edgex20261NN/ has only concentration_limits_configs.py + thresholds.py + constants.py) and per wm-ku5sen never materialized in prod, so a deal-level CNL is not queryable today.
