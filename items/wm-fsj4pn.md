---
id: wm-fsj4pn
type: task
title: Stop my 4 stale dagster stacks on dpx (Kabeer's ask)
status: done
created: 2026-09-03T18:52:46Z
updated: 2026-09-03T19:01:42Z
source: claude-code
---

Kabeer asked 2026-09-04 whether the dagster daemons on dpx can be stopped. Box: load avg ~42, 24 dagster containers, 12 of them mine (4 stacks x 3 containers).

All four of my stacks are idle:
- dagster-*-abhishek (/home/abhishek/repos/efp) - last run 2026-08-31, 258 runs, port 13053
- dagster-*-abhishek-itd (~/claude-ws/openroad-itd/efp) - last asset job 2026-08-31, last real job 2026-08-26, ports 13060/13432
- dagster-*-abhishek-dev1498 (~/claude-ws/dev-1498/efp) - last run 2026-08-26, port 13098
- dagster-*-abhishek-dev1499 (~/claude-ws/dev-1499/efp) - last run 2026-08-31, port 13099

No sensors or schedules registered in any of them (instigators table empty, 0 job_ticks), and no established connections to any webserver port. Postgres data is on named volumes, so `docker compose stop` / `down` (without -v) is non-destructive; restart with `docker compose up -d` from each workdir.

dev-1499 is the OpenRoad CMOP/BEP workspace (see the OpenRoad CMOP/BEP item) - stopping it is still cheap, it comes back in seconds.

## Log
- 2026-09-03T18:55Z [claude-code] Confirmed no job activity: 0 runs and 0 event-log rows in the last 24h in all four stacks, and no dagster execute_run worker process in any container. The only non-terminal run is a zombie STARTED __ephemeral_asset_job__ from 2026-07-24 in the abhishek stack (no events after create). The abhishek daemon is respawning grpc code servers every minute or so - CPU churn, not work.
- 2026-09-03T19:01Z [claude-code] Stopped the 9 containers of the three stale stacks (itd, dev1498, dev1499) on 2026-09-03 19:01 UTC at Abhishek's instruction; left the ~/repos/efp stack (dagster-*-abhishek, port 13053) running. Postgres exited 0 cleanly in all three, webservers took SIGKILL after the stop timeout (normal). Box load avg went 42 -> 32 over the following minutes. Restart any of them with: docker start dagster-postgres-<stack> dagster-daemon-<stack> dagster-webserver-<stack> (or docker compose up -d from the workdir in an interactive shell - the compose plugin is not on the non-interactive ssh PATH).
