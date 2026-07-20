---
id: wm-qcg2m9
type: task
title: Coder workspace: template fixes to request (k8s-devcontainer)
status: open
created: 2026-07-20T16:07:51Z
updated: 2026-07-20T17:40:52Z
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

## Log
- 2026-07-20T16:18Z [claude-code] Dagster test on Coder 2026-07-20: 'make dg-start' UNUSABLE (docker-compose based, no docker daemon on Coder). Native 'dagster dev' works after two fixes: (1) dagster-webserver not in repo .venv - only in Docker image; installed dagster-webserver==1.12.14 (~1s). (2) orchestration/workspace.yaml hardcodes working_directory /app/orchestration (container path), and 'efp' module lives at lib/efp (pyproject packages=[edgefocus, lib/efp]) but isn't installed into venv - native runs need PYTHONPATH=REPO:REPO/lib plus a local workspace yaml (/tmp/ws_local.yaml). Result: 305 assets / 42 jobs on :3011, SQLite instance at /tmp/dagster_home_test. DPX: 309 assets / 41 jobs (commit 162a7660a vs coder c894d400f), postgres-backed on :13053, containers up 4wk. PROPOSAL: add a 'make dg-dev' target for native non-docker dagster that sets PYTHONPATH and generates local workspace.yaml - makes repo usable on docker-less envs.
- 2026-07-20T17:40Z [claude-code] Docker feasibility on Coder — DEFINITIVE NO from inside the pod (tested 2026-07-20). sudo DOES give real root (uid=0) and apt works, but the pod has no CAP_SYS_ADMIN: CapEff=0x0, bounding set excludes cap_sys_admin/cap_net_admin. Even as root, 'unshare --mount', '--net', '--pid' all fail with EPERM, and 'mount -t tmpfs' is denied. max_user_namespaces=0 and no /dev/fuse, so rootless Docker AND Podman are also impossible. iptables not installed. dockerd binary not present (only docker CLI + compose plugin v5.3.1). User IS in group docker (gid 1001) — template appears to intend a socket mount that never happens. Docker requires a TEMPLATE/cluster change: privileged pod, DinD sidecar, sysbox runtime, or mounting the host socket. Not user-fixable.

PERSISTENCE CORRECTION: only /home/coder persists — it is a 40G ext4 PVC (/dev/nvme2n1), 34G free. Earlier '72G of 99G free' was WRONG: that was the ephemeral overlay rootfs. Terraform recreates kubernetes_pod_v1.main on every start, so / is rebuilt from the image each time — ALL apt installs are lost on restart. Anything to persist must live under /home/coder or go into the template image. Also noted: NFS mounts at /homes (ro) and /home/abhishek (rw) inside the pod.
