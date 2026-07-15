#!/usr/bin/env bash
# Idempotent setup for the task memory on a new (or this) machine.
# Usage: git clone <remote> ~/taskmem && ~/taskmem/install.sh [--cron]
#   --cron  also install the crontab block (review agents, autosync, dashboard)
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAME="$(basename "$DIR")"
CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
CLAUDE_MD="$CLAUDE_DIR/CLAUDE.md"
CRON_BEGIN="# >>> $NAME >>>"
CRON_END="# <<< $NAME <<<"

echo "== task memory installer ($DIR) =="

# --- 1. dependencies (zero Python deps by design) ---------------------------
command -v python3 >/dev/null || { echo "ERROR: python3 required"; exit 1; }
command -v git >/dev/null || { echo "ERROR: git required"; exit 1; }
command -v claude >/dev/null \
    || echo "WARN: claude CLI not found — cron review agents won't run until installed"

# --- 2. CLI on PATH ----------------------------------------------------------
mkdir -p "$HOME/.local/bin" "$DIR/.logs"
chmod +x "$DIR/bin/taskmem" "$DIR/bin/session-context" "$DIR/bin/dashboard" "$DIR/bin/agent-brief"
ln -sf "$DIR/bin/taskmem" "$HOME/.local/bin/$NAME"
ln -sf "$DIR/bin/taskmem" "$HOME/.local/bin/tm"
echo "ok: CLI -> ~/.local/bin/$NAME (and tm)"

# --- 3. git repo -------------------------------------------------------------
[ -d "$DIR/.git" ] || git -C "$DIR" init -q
echo "ok: git repo"

# --- 4. Claude Code hooks: inject task state into every session --------------
mkdir -p "$CLAUDE_DIR"
DIR="$DIR" python3 - "$SETTINGS" <<'PY'
import json
import os
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
settings = json.loads(path.read_text()) if path.exists() else {}
hooks = settings.setdefault("hooks", {})
cmd = os.environ["DIR"] + "/bin/session-context"
for event, argv in [("SessionStart", cmd), ("SubagentStart", cmd + " SubagentStart")]:
    entries = hooks.setdefault(event, [])
    if not any("bin/session-context" in h.get("command", "")
               for e in entries for h in e.get("hooks", [])):
        entries.append({"hooks": [{
            "type": "command", "command": argv, "timeout": 15,
            "statusMessage": "Loading task memory...",
        }]})
path.write_text(json.dumps(settings, indent=2) + "\n")
print("ok: SessionStart/SubagentStart hooks in", path)
PY

# --- 5. global CLAUDE.md points at the protocol -------------------------------
if [ ! -f "$CLAUDE_MD" ] || ! grep -q "$NAME/AGENTS.md" "$CLAUDE_MD"; then
    cat >> "$CLAUDE_MD" <<EOF

# Shared task memory (~/$NAME)

A shared task memory for all AI agents lives at \`$DIR\` — markdown work
items + a generic CLI (\`$DIR/bin/taskmem\`, on PATH as \`$NAME\` and \`tm\`).
Session start: check it (\`tm search "<topic>"\`). During and before ending a
session: follow \`$DIR/AGENTS.md\` — infer commitments, update items, log
outcomes, mark done work, sync. Set \`WM_AGENT=<your-role>\` when mutating.
EOF
    echo "ok: appended pointer block to $CLAUDE_MD"
else
    echo "ok: $CLAUDE_MD already references the protocol"
fi

# --- 6. crontab (only with --cron; marker-delimited, replaced wholesale) -----
if [ "${1:-}" = "--cron" ]; then
    TMP="$(mktemp)"
    { crontab -l 2>/dev/null | sed "/^$CRON_BEGIN\$/,/^$CRON_END\$/d"; } > "$TMP" || true
    cat >> "$TMP" <<EOF
$CRON_BEGIN
# Reminders only — cron never invokes claude itself (user policy).
30 8 * * 1-5 $DIR/bin/taskmem notify "taskmem" "Morning brief: run  agent-brief daily" > /dev/null 2>&1
0 14 * * 1-5 $DIR/bin/taskmem notify "taskmem" "Inbox sweep: run  agent-brief intake" > /dev/null 2>&1
0 17 * * 5 $DIR/bin/taskmem notify "taskmem" "Weekly review: run  agent-brief weekly" > /dev/null 2>&1
*/15 * * * * $DIR/bin/taskmem sync > /dev/null 2>&1
20 9 * * 0,6 $DIR/bin/dashboard > /dev/null 2>&1
$CRON_END
EOF
    crontab "$TMP" && rm -f "$TMP"
    echo "ok: crontab block installed (times are this box's TZ: $(date +%Z))"
else
    echo "skip: crontab (rerun with --cron to install review agents + autosync)"
fi

# --- 7. smoke test + dashboard ------------------------------------------------
"$DIR/bin/taskmem" find --count
"$DIR/bin/dashboard"
echo "== done. New Claude Code sessions will load task state automatically. =="
