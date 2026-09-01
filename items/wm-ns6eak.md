---
id: wm-ns6eak
type: task
title: Resolve per-loan cfframe config for conda-path predictions (blocks CMOP/BEP cashflows on 4 channels)
status: open
created: 2026-09-01T18:23:20Z
updated: 2026-09-01T18:23:20Z
source: claude-code
---

populate_predicted_cashflows._build_config_from_row does float(row['RECOVERY_FRAC']) / float(row['SERVICING_FEE']). Channels whose cfframe config declares those as per-loan COLUMN NAMES rather than scalars -- anchored_auto_indirect, anchored_indirect, foursight_auto_indirect, innovate_auto_refi, openroad_auto_refi -- get NULL embedded by the conda predictor, because base.numeric_or_none() drops str to None. float(None) then raises.

Verified: openroad DEV curr_mod 2,507/2,507 and best_est 1,067/1,067 rows NULL on both; anchored PROD curr_mod 163,158 and best_est 105,318 rows likewise; _build_config_from_row raises on anchored's own PROD row against master.

UNRESOLVED: anchored's prod cashflows ARE written (LOADED_AT 2026-08-30 / 08-27). Ruled out a recent regression (#5509/#5620), dtype inference at scale (full 136,107-row slice is object/None), the dated-vs-dateless S3_BASE change (#6285), and a matching Sentry error. Likely prod runs a revision differing from master -- needs prod deploy visibility.

Fix belongs in the pipeline's config embedding or in _build_config_from_row, mirroring the per-loan resolution openroad_api_predictions.py already does in SQL for at_orig. A fillna would fabricate a model input: real values vary per loan (openroad 0.32-0.46, anchored 0.226-0.673).
