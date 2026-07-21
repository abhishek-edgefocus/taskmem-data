---
id: wm-hhacw8
type: bug
title: Docs pushed agents into JSON-parsing pipelines to read an item, instead of just reading the markdown file
status: inbox
tags: [taskmem-bug]
created: 2026-07-21T12:28:16Z
updated: 2026-07-21T12:28:16Z
source: claude-code
label: Docs pushed agents into JSON-parsing
---

Abhishek caught an agent reading two items like this:

  cd ~/taskmem && for i in wm-wn8wbk wm-qu4cr7; do echo "##### $i"; ./bin/taskmem get $i 2>&1 \
    | python3 -c "import sys,json;d=json.load(sys.stdin);print('T:',d['title']);...;print(d.get('body','')[:700])"; done

Every part of that is avoidable. The whole thing is `tm get wm-wn8wbk wm-qu4cr7 --raw`:
`get` already takes nargs="+" so the loop is unnecessary; `--raw` already emits the
markdown so the python reformatter is unnecessary; `tm` is on PATH so the `cd` is
unnecessary. For a single known item, reading `items/<id>.md` is simpler still — they
are small plain-markdown files (wm-qu4cr7.md is 504 bytes).

WORST PART — the `[:700]` truncation. On wm-wn8wbk that cut lands mid-item and drops
the deliverable line and the Slack thread permalink, so the agent reasons about
Dustin's CNL request from a fragment. That is the SAME root cause as the stale-info
corrections (wm-k8ppvk, wm-h7tqbn, wm-y7dqmg): confident assertion from partial
context. A truncating read is a silent context-loss bug, not a formatting choice.

ROOT CAUSE (docs, not agent judgment): SCHEMA.md opened the CLI contract with "All
output is JSON (JSONL for find/search)" and AGENTS.md routed every interaction through
the CLI, while nothing anywhere said the item files are readable markdown and are the
record. An agent reading only those two documents correctly concludes it must call the
CLI and parse JSON to see anything. The docs specified a gate where none exists.

FIXED IN THIS COMMIT: AGENTS.md gains a "Reading vs querying vs mutating" section
(read the file or `get --raw`; never pipe get through a JSON parser; NEVER truncate a
body; CLI for cross-item queries and for every mutation; never hand-edit a file
because that loses `updated`, `## Log`, attribution and the commit). SCHEMA.md's CLI
contract now says the JSON is for programs needing fields, not a hoop for reading.

## Next steps
1. Watch whether agents still build JSON pipelines after this wording lands; if they
   do, the fix is a mechanism, not more prose (same lesson as inbox-vs-next, which
   needed a CLI warning before it stuck).
2. Consider whether `get` without --raw should hint at --raw for human reading.


## Environment
- taskmem: ca26d82
- reported by: claude-code
- host: ip-192-168-0-103.ap-south-1.compute.internal
- when: 2026-07-21T12:28:16Z
