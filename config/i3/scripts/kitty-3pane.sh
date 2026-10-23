#!/usr/bin/env bash
set -e

LAYOUT="$HOME/.config/i3/layouts/kitty-3pane.json"
WORKSPACE="9"

# Evita di ricreare il layout se è già aperto sulla workspace 9
CURRENT_WS=$(i3-msg -t get_workspaces | python3 -c '
import json,sys
for w in json.load(sys.stdin):
    if w.get("focused"):
        print(w["name"])
        break
')

if [ "$CURRENT_WS" = "$WORKSPACE" ]; then
    exit 0
fi

i3-msg "workspace $WORKSPACE" >/dev/null
i3-msg "append_layout $LAYOUT" >/dev/null

kitty &
sleep 0.7
kitty &
sleep 0.7
kitty &
