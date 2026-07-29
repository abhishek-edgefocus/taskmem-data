---
id: wm-mmmc9t
type: task
title: Take over the Experian Activate dockerised model from Nakula (ex-Lloyd) + Nate's adjustments
status: next
priority: p2
size: m
people: [Trishit, Nate, Nakula]
tags: [northpond, ownership]
links: [parent:wm-j523sq]
refs: [dm-thread=https://edgefocuspartners.slack.com/archives/D0B8A1T4S0N/p1785262559117759]
created: 2026-07-29T13:42:33Z
updated: 2026-07-29T15:32:30Z
source: claude-code
label: Experian Activate model handover
---

Abhishek now owns the packaged/dockerised Experian model that Edge Focus deployed into the
**Experian Activate marketing environment** — Experian Activate hosts it so they can run
better marketing for us. Confirmed directly by Nate Wong in DM on 2026-07-29 20:53 IST.

HOW OWNERSHIP LANDED (Trishit DM D0B8A1T4S0N, 2026-07-28 23:45 IST onward):
- Trishit: "are you the one who would be looking at the Docker model for Oliv?"
- The v1 (TU) model for Oliv is hosted on Experian's website — there is NO v1 container.
- The v2 container was managed by Lloyd, then transitioned; Trishit had forgotten to whom.
- Abhishek checked #team-devs: it went to Nakula, who has not touched it since. Nakula is
  fine with Abhishek taking it over; Abhishek told Trishit so on 2026-07-29 18:56.
- Trishit 18:57: "Nate wanted some adjustments made to the docker container so should I
  mention you or Nakula for the same?" Abhishek: "You can mention me."

NEXT STEPS, in order:
1. **Get a formal KT from Nakula.** Abhishek told Nate on 2026-07-29 21:00: "I haven't had
   a formal KT yet, so my understanding is still fairly limited." Nothing else here can be
   scoped properly until this happens. Nakula has not touched the container since receiving
   it from Lloyd, so budget for the handover being thin.
2. Get the concrete list of adjustments Nate wants. Trishit relayed that the ask exists,
   not its content — it is still unspecified anywhere.
3. Then scope.

Note on naming: `northpond_docker_model` is already an entry in models_by_channel.json (see
[[wm-9s2mwd]]), so the container is registered on the model-artifact side.

Nate's separate follow-up topic — early-results analyses on this model — is [[wm-htwqte]].

## Log
- 2026-07-29T15:32Z [claude-code] CORRECTION 2026-07-29: this item was created earlier today titled 'Take over the Oliv v2 model Docker container'. Nate's DM at 20:53 IST names it precisely — it is the Experian model deployed into the EXPERIAN ACTIVATE MARKETING ENVIRONMENT, a packaged/dockerized model Experian Activate hosts to facilitate marketing for us. That is consistent with Trishit's 'the v2 model is hosted on Experian's website' (same container), but the purpose is marketing enablement, not only realtime loan scoring — the original title implied the latter. Title and body corrected.
Also captured from Nate's DM: Abhishek confirmed ownership publicly to Nate at 21:00 IST and volunteered that no formal KT has happened yet. Promoted the KT from Nakula to step 1.
