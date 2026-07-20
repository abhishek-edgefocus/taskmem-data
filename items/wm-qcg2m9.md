---
id: wm-qcg2m9
type: task
title: Coder workspace: template fixes to request (k8s-devcontainer)
status: open
created: 2026-07-20T16:07:51Z
updated: 2026-07-20T16:07:51Z
source: claude-code
---

Evaluated abhishek-coder-workspace-1 (k8s-devcontainer) on 2026-07-20 vs dpx.

Working: uv 0.11.24 + Python 3.13.11, efp repo cloned with .venv, full stack imports (pandas/pyarrow/snowflake/dagster), jupyterlab auto-running on 8888 with 'efp' kernel registered, AWS SSO role coder-workspace-dev valid, home PVC persists across stop/start.

Template issues to raise with whoever owns k8s-devcontainer:
1. No ~/.bashrc or ~/.profile — the home PVC mount hides /etc/skel, so ~/.local/bin never lands on PATH. This is why the Claude Code CLI/extension appeared broken. Worked around locally by writing both files 2026-07-20.
2. No docker daemon/socket (docker CLI present but /var/run/docker.sock absent). Also makes `coder show` throw a 500 on the devcontainers API.
3. node only inside /opt/micromamba/envs/efp_env/bin, not on PATH.
4. Jupyter server rooted at /home instead of /home/coder.
5. psql and direnv missing.

Perf: cold start 3m13s (pod schedule); uv venv + pandas/numpy/pyarrow/jupyterlab = 3.9s; efp imports 6.6s. 4 vCPU / 30Gi RAM vs dpx 16 core / 501Gi.
