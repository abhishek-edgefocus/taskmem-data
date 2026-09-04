---
id: wm-su6q4d
type: project
title: OpenRoad Data Ingestion
status: active
tags: [openroad]
created: 2026-07-15T14:44Z
updated: 2026-09-04T11:46:17Z
source: dpx-tasks import
label: OpenRoad ingestion project
---

OpenRoad silver ingestion + predictions validated end to end

## Log
- 2026-07-15T14:44Z [importer] created from dpx ~/tasks projects.yaml
- 2026-09-04T11:46Z [claude-code] Reviewed sanjali's PR #6651 (DEV-1756, flat openroad statement-row modules -> openroad/ package). Verified it is a pure move: git shows 4 renames at 94-98% similarity, openroad_constants.py merged into openroad/constants.py with no symbol overlap, only importer in the repo (orchestration/assets/openroad_assets.py) updated, Dagster asset_name strings and table names unchanged, CI green. Told Abhishek it is safe to approve with no comments.
