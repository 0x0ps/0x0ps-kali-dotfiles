#!/usr/bin/env bash
# 0x0ps VictorConky auto-hide for i3.
# Hide the desktop HUD while any managed application window exists;
# show it again when the i3 tree is empty.

set -u

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/0x0ps-conky-autohide-${UID}.lock"
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

CONKY_ID=""

# Conky starts immediately before this helper in the i3 config.
for _ in {1..60}; do
    CONKY_ID="$(xdotool search --class '^conky$' 2>/dev/null | head -n 1 || true)"
    [[ -n "$CONKY_ID" ]] && break
    sleep 0.5
done

if [[ -z "$CONKY_ID" ]]; then
    printf '%s\n' "conky-autohide: Conky window not found; exiting." >&2
    exit 1
fi

sync_conky_visibility() {
    local window_count

    window_count="$(i3-msg -t get_tree 2>/dev/null | jq -r '[.. | objects | select(.window? != null and .window_properties? != null)] | length' 2>/dev/null || printf '0')"

    if [[ "$window_count" =~ ^[0-9]+$ ]] && (( window_count > 0 )); then
        xdotool windowunmap "$CONKY_ID" >/dev/null 2>&1 || true
    else
        xdotool windowmap "$CONKY_ID" >/dev/null 2>&1 || true
    fi
}

# Apply the correct state immediately, then react to window/workspace events.
sync_conky_visibility

while IFS= read -r _event; do
    sync_conky_visibility
done < <(i3-msg -t subscribe -m '[ "window", "workspace" ]')
