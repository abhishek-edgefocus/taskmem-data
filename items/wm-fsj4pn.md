---
id: wm-fsj4pn
type: task
title: Stop my 4 stale dagster stacks on dpx (Kabeer's ask)
status: done
created: 2026-09-03T18:52:46Z
updated: 2026-09-03T23:12:41Z
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
- 2026-09-03T23:05Z [claude-code] Stopped the last stack too (dagster-daemon/webserver/postgres-abhishek, ~/repos/efp, port 13053) at 2026-09-03 23:05 UTC on request. Zero dagster containers of mine now running on dpx; only dagster-postgres-eshan (someone else's orphaned db, daemon+webserver already down) remains up box-wide. Box load avg ~9.9, down from 42. Restart mine with: docker start dagster-postgres-abhishek dagster-daemon-abhishek dagster-webserver-abhishek (postgres first). All four stacks keep their named volumes and run history.
- 2026-09-03T23:08Z [claude-code] Followed up with the repo-standard teardown: make dg-stop is orchestration/scripts/stop.sh = docker-compose -p dagster-$(whoami) down (removes containers + network, keeps the named volume) and only ever targets the dagster-<user> project, so it could not have touched the claude-ws stacks. Ran docker-compose down for all four project names (dagster-abhishek in ~/repos/efp, openroaditd in ~/claude-ws/openroad-itd, dagster-abhishek-dev1498 in ~/claude-ws/dev-1498, orchestration in ~/claude-ws/dev-1499). All 12 containers and 4 dagster-network-abhishek* networks removed; all four postgres volumes still present, run history intact. Note docker-compose (v1 path /usr/local/bin/docker-compose) works over non-interactive ssh, plain 'docker compose' does not. Bring the main one back with: cd ~/repos/efp && make dg-start.
- 2026-09-03T23:12Z [claude-code] Found five bare-metal dagster-webserver instances running outside Docker under my user - they never appeared in docker ps: ~/repos-2/efp on 13054 (41 days), claude-ws/oliv-exp on 13077 (34d), claude-ws/openroad-gold on 13078 (34d), claude-ws/dev-1516 on 13079 (14d), claude-ws/dev-1539 on 13080 (14d). All were uv run dagster-webserver -m orchestration.definitions launched with setsid by past agent sessions, SQLite-backed, webserver-only (no daemon). Killed all 15 processes 2026-09-03 23:12 UTC (SIGTERM ignored, needed SIGKILL); ports all free. Lesson: docker ps alone does not prove nothing dagster is running on dpx - also check ps -u <user> | grep dagster.
