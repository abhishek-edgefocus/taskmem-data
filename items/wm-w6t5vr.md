---
id: wm-w6t5vr
type: bug
title: anchored CMOP/BEP cashflows model ZERO recoveries in prod (NaN recovery_frac silently swallowed)
status: open
created: 2026-09-02T13:19:01Z
updated: 2026-09-02T13:19:01Z
source: claude-code
---

Found 2026-09-02 while blast-radius testing for openroad CMOP ([[wm-udqmrm]], [[wm-xe6w4q]]).

PROD.SILVER.PREDICTED_CASHFLOWS_HISTORY, PREDICTION_TYPE curr_mod:

| platform | rows | null RECOVERY | zero RECOVERY | TOTAL_RECOVERY | TOTAL_CHARGEOFF |
|---|---|---|---|---|---|
| anchored (NaN config) | 233,745 | 138,720 | 95,025 | **0.00** | 7,801,764 |
| happymoney (scalar) | 1,853,639 | 398,543 | 343,432 | 6,501,406 | 130,028,100 |
| sofi (scalar) | 8,279,280 | 2,782,291 | 731,169 | 36,881,032 | 461,012,900 |

Anchored models 7.8M of chargeoffs with LITERALLY ZERO recovery, while comparable platforms recover ~5% of chargeoff. Every anchored recovery row is null or zero.

MECHANISM, fully traced. anchored_auto_indirect's cfframe config declares recovery_frac as the per-loan column name 'recovery_fraction_ltv' and servicing_fee as 'servicing_fee'. base.numeric_or_none() drops str to None, so the conda predictor embeds NULL in silver.predictions. Then in populate_predicted_cashflows._build_config_from_row, float(row['RECOVERY_FRAC']) receives NaN -- not None -- because predicted_cashflows always loads several platforms' s3_bases together and the healthy platforms' real values make the column float64, so anchored's NULLs arrive as NaN. float(nan) succeeds, CFFrameConfig gets recovery_frac=nan, and the cfframe math yields no recoveries. No error, no log line, no Sentry.

This also RESOLVES the tension I could not explain across several sessions -- why anchored's cashflows are written fine in prod while the same function raises TypeError on anchored's own prod row in isolation. Verified directly: loading the openroad slice ALONE gives dtype=object, value None, float() raises; loading it alongside a healthy slice gives dtype=float64, value nan, float() returns nan. Prod never loads a slice alone, so it never raises -- it silently NaNs instead.

AFFECTED CHANNELS: every string-sentinel cfframe config -- anchored_auto_indirect, anchored_indirect, foursight_auto_indirect, innovate_auto_refi, openroad_auto_refi. Only those with live conda-path CMOP/BEP are actually wrong today; anchored is confirmed, the others need checking.

Fix is the same one tracked on [[wm-ns6eak]]: resolve recovery_fraction_ltv / servicing_fee per loan when embedding, the way openroad_api_predictions.py already does in SQL for at_orig. A defensive guard rejecting NaN in _build_config_from_row would at least make it loud instead of silent.
