---
id: wm-mmmc9t
type: task
title: Take over the Oliv v2 model Docker container from Nakula (ex-Lloyd) + make Nate's requested adjustments
status: next
priority: p2
size: m
people: [Trishit, Nate, Nakula]
tags: [northpond, ownership]
links: [parent:wm-j523sq]
refs: [dm-thread=https://edgefocuspartners.slack.com/archives/D0B8A1T4S0N/p1785262559117759]
created: 2026-07-29T13:42:33Z
updated: 2026-07-29T13:42:33Z
source: claude-code
label: Oliv v2 docker container handover
---

Trishit DM, 2026-07-28 23:45 IST onward, continued 2026-07-29 18:57.

What was established in that exchange:
- Trishit: "are you the one who would be looking at the Docker model for Oliv?"
- The v1 (TU) model for Oliv is hosted on Experian's website — there is NO v1 container.
- The v2 container was managed by Lloyd, then transitioned; Trishit had forgotten to whom.
- Abhishek checked #team-devs: it went to Nakula, who has not touched it since. Abhishek
  confirmed with Nakula that he is fine with Abhishek taking it over, and told Trishit so
  on 2026-07-29 18:56.
- Trishit 18:57: "Nate wanted some adjustments made to the docker container so should I
  mention you or Nakula for the same?" Abhishek: "You can mention me."

SO: Abhishek now owns the Oliv v2 model Docker container.

OPEN — the actual adjustments Nate wants are NOT yet specified anywhere. Trishit relayed
the existence of the ask, not its content. First step is to get the concrete list from
Nate (or from Trishit, who heard it), then scope.

Related but distinct: `northpond_docker_model` is already an entry in models_by_channel.json
(see [[wm-9s2mwd]]), so the container is registered on the model-artifact side.
