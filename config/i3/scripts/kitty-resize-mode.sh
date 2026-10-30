#!/usr/bin/env bash
set -euo pipefail

# Enter Kitty-only resize mode, converting the focused Kitty window to floating.
focused_id="$(
    i3-msg -t get_tree |
        jq -r '.. | objects | select(.focused == true and .window_properties.class? == "kitty") | .id' |
        head -n 1
)"

if [[ -z "${focused_id}" ]]; then
    notify-send "0x0ps i3" "Focus a Kitty window before entering Kitty resize mode."
    exit 1
fi

i3-msg "[con_id=${focused_id}] floating enable" >/dev/null
i3-msg 'mode "kitty-resize"'
