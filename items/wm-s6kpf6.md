---
id: wm-s6kpf6
type: task
title: Take over NorthPond API ownership from Kabeer — discuss scope with Abhijeet Friday 2026-07-31
status: next
priority: p2
size: m
due: 2026-07-31
people: [Abhijeet, Kabeer]
tags: [northpond, oncall, ownership]
links: [parent:wm-j523sq]
refs: [dm=https://edgefocuspartners.slack.com/archives/D0B2A3WSJ5N/p1785263143379249]
created: 2026-07-29T13:42:49Z
updated: 2026-08-24T17:03:02Z
source: claude-code
label: NorthPond API ownership handover
---

Abhijeet DM, 2026-07-28 23:45 IST - 2026-07-29 00:20 IST (D0B2A3WSJ5N).

Abhishek asked whether the realtime loan-scoring model work falls under "Everything
NorthPond" (his remit). Abhijeet: "Ho gheu shaktos" (yes you can take it) — but first ask
on #team-devs whether someone is already working on it and take over from them if so.
Then, unprompted: "API pan take over kar Kabeer kadun (pudhchya veli kahi issue vagare ala
tar tu kar fix)" — take the NorthPond API over from Kabeer too, and you fix it next time
something breaks.

Abhijeet was unsure himself whether the scoring model is Oliv-side ("oliv chya side cha
ahe ka kahi, sahebanna vichar" — ask Sean/Nate), and closed with "friday la boluya hya
baddal / sakhol charcha karu" — let's talk about this Friday, in depth.

FRIDAY 2026-07-31 IS THE ACTION. What needs settling there:
- Exact boundary of "NorthPond API" ownership passing from Kabeer to Abhishek.
- Whether the realtime v2/Experian loan-scoring model is in scope or is Oliv-side.
- Handover of anything Kabeer holds (creds, runbooks, alert routing).

ALREADY MOVING IN THAT DIRECTION — on 2026-07-29 Abhijeet assigned Abhishek three
Experian/NorthPond error tickets (ERROR-1178, ERROR-400, ERROR-1647; Abhishek: "Kar
assign"). Tracked separately.

Adjacent ownership handover in flight: the Oliv v2 model Docker container — [[wm-mmmc9t]].

## Log
- 2026-07-31T12:56Z [claude-code] HUDDLE HAPPENED 2026-07-31 17:18 IST (D0B2A3WSJ5N). Abhijeet at 17:07: 'free jhalas ki sang' (tell me when you're free); Abhishek at 17:12: '5 mins ne huddle karto'; Slackbot logged a huddle start at 17:18. This is the Friday conversation this item was created for.
CONTENT UNKNOWN — huddles leave no transcript, so whether the NorthPond API ownership boundary, the Kabeer handover, or the realtime-scoring-model scope question actually got settled cannot be read from Slack. Leaving status=next rather than assuming it closed; needs Abhishek to confirm what was agreed, or to mark done.
- 2026-08-24T17:03Z [claude-code] NORTHPOND GATEWAY DEPLOYMENT — mapped 2026-08-24 (Abhishek is taking over API ownership and had not seen this).

MECHANISM. Two containers per EC2 instance from one ECR repo {channel}-{deploy_mode}, tagged by COMMIT SHA: gateway (port 5000, bin.json_endpoints.json_endpoint_server) and model microservice (port 5556, bin.model_microservice.app). Deployed by AWS CDK -> ASG behind an ALB target group: cdk deploy --context channel=northpond_loan_fl --context deploy=production --context gateway_branch=<ref> --context model_tag=<ref> (devops/endpoint/aws_cdk/app.py resolves both refs to hexsha). Gateway and model are versioned INDEPENDENTLY. Triggered from Jenkins on admin.edgefocus.net (templates: devops/endpoint/jenkins/auto-scalable.template). deploy modes are production|sandbox only.

FULLY MANUAL. No GitHub Actions workflow deploys endpoints -- .github/workflows has dagster deploys only. Merging to master does NOT ship the gateway. Someone must run the Jenkins job.

ROLLOUT SAFETY. ASG rolling update max_batch_size=1, min_instances_in_service=1, min_healthy=100% / max_healthy=200%, so a new instance launches before the old drains. northpond min=1 max=2 desired=1. New instance user-data BLOCKS on 'until curl -sf http://127.0.0.1:5000/server-status' -- /server-status only returns 200 once the co-located model has finished cold-loading (Samuel's DOPS-371 #5771, later DOPS-679), so the cfn success signal is withheld and the old box stays in service until the new one can actually serve. Budget is WARMUP=35min (Signals.wait_for_all timeout). ALB health check /server-status, 200 only, 10s interval, 2 consecutive passes. DrainOnTerminate lifecycle hook, 5min heartbeat. Rollback = redeploy an older gateway_branch ref; old SHA-tagged images stay in ECR.

TESTING. ci_tests.yml runs on PRs (ruff/mypy/pytest). endpoint_tests.yml ('Endpoint Tests' -> devops/scripts/github_tests/model_sanity_check.py, runs Sim + Mimic Endpoint) is workflow_dispatch ONLY -- manual, takes channels + run_sim. Local: devops/endpoint/docker-compose.py with devops/endpoint/.env (DEPLOY_MODE=unittest).
NO SANDBOX EXISTS. Zero -sandbox ASGs for ANY channel; sandbox is a valid deploy mode in code but nothing runs there. There is no staging tier for endpoints today.

THE HEADLINE FINDING. Production northpond gateway is running 622bb331e from 2026-07-13 -- 413 commits behind master. Model microservice is b04ca1f63 from 2026-07-02. Launch template is at v61 (2026-07-13) and that is also the newest version; last ECR image push for this channel was 2026-07-13. Nothing has been built or deployed for northpond in six weeks.
=> Samuel's #6425 (merged 2026-08-21) is NOT in production. Its 400-handling and the status-code plumbing our #6416 builds on are both un-deployed.
=> #6416 will change nothing in prod until someone runs the Jenkins deploy, and when they do it carries 413 commits of unrelated change with it -- far bigger blast radius than our two files.
=> The 'watch the retry warning line after deploy' verification plan is blocked on that deploy happening.

PEER COMPARISON (last deploy per channel): upgrade 08-24, anchored 08-21, sofi 08-21, foursight 08-20, prosper 08-17, happymoney 08-14, tare + credible 08-07, revolut 08-05, NORTHPOND 07-13, openroad 06-24. So northpond's staleness is anomalous, not the house norm.

OWNER TO ASK: samueli-efp owns this stack -- most recent devops/endpoint commits are his (DOPS-632 #6164, DOPS-621 #6063, DOPS-371 #5771, credible cdk #6066).
