---
id: wm-wcawuj
type: task
title: Give the NorthPond comparison board an 'only unverified' filter
status: open
priority: p3
size: s
tags: [northpond]
links: [parent:wm-3sxcre]
created: 2026-07-29T16:39:10Z
updated: 2026-08-14T19:57:12Z
source: claude-code
---

northpond_verified.py landed in PR #6058, but it does NOT make the Grafana board read clean — that was a wrong assumption I held early and corrected before merge.

The Python registry (edgefocus/transformations/silver/comparison/*_verified.py) is consumed ONLY by the CLI report compare_datastore_positions.py, which tags a column [VERIFIED] and keeps it out of unverified_issues. compare_daily_summary.py, which writes GOLD.POSITIONS_COMPARISON_DAILY behind the boards, has zero references to verified differences — it emits raw mismatch % keyed by Snowflake column name.

How a board actually filters, per Eshan's Upgrade board (uid 0f070087):
- a Grafana CONSTANT variable 'verified_cols' — a hand-maintained comma-separated list of SNOWFLAKE column names ('ACCRUED_INTEREST','APR_AT_PURCHASE',...)
- a custom variable 'show_mode' with values 'Only unverified' / 'All'
- every panel wraps each column: CASE WHEN '${show_mode}'='All' OR 'COL' NOT IN (${verified_cols}) THEN COL END

The NorthPond board (uid 98ba2ef7-1b1c-4954-bf5a-87bfd8664593) has neither variable — only 'database'.

## Next steps
1. Add show_mode + verified_cols to the NorthPond dashboard JSON, seeding verified_cols with the SNOWFLAKE names of the 21 columns now in northpond_verified.py (note the ITD ones map cum_payment_* -> ITD_PAYMENT_*).
2. Wrap the per-family panel queries in the same CASE pattern.

Worth noting the duplication this creates: the same verified list then lives in two hand-maintained places, Python and dashboard JSON, with different column-name conventions. If this gets done for more platforms, generating the Grafana variable from the Python registry would be the better shape.

Do this after the comparison job is producing rows again — otherwise there is nothing current to look at.
