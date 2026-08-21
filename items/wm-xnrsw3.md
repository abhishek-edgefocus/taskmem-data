---
id: wm-xnrsw3
type: bug
title: tm set with only a next= field silently flipped status to done
status: inbox
tags: [taskmem-bug]
created: 2026-08-21T14:51:06Z
updated: 2026-08-21T14:51:06Z
source: claude-code
label: tm set with only
---

Ran, on an item whose status was `next`:

    tm set wm-hbujve 'next=Recheck after 2026-08-21 16:00 UTC ...'

Intent was to update only the `next` field. The command set the `next` text
correctly but ALSO changed `status` from `next` to `done`, with no warning in
the JSON result beyond the status field itself. Caught only because the result
was piped through a check that printed the status.

Suspected cause: the literal `next=` key colliding with status-shorthand
parsing (a bare `next` presumably being read as a status keyword somewhere in
the arg handling), so the parser consumed it as a state transition as well as
a field write.

Impact: an item silently marked complete while work remained. On this item the
work genuinely was still open — a Grafana/Linear recheck due after the next
scheduled run. Anything reading the digest between the bad `set` and the fix
would have seen it as finished and dropped it.

Fixed by re-running `tm set wm-hbujve status=next`.

Worth either rejecting `next=` as a field name, namespacing it, or refusing
any `set` that changes status without status= being passed explicitly.

## Environment
- taskmem: a1d8ed5
- reported by: claude-code
- host: ip-192-168-0-102.ap-south-1.compute.internal
- when: 2026-08-21T14:51:06Z
