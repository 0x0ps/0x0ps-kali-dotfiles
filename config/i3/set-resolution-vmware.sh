#!/usr/bin/env bash
# 0x0ps Kali - VMware dynamic resolution handler for i3/X11.
# Applies the preferred Virtual-* mode advertised by VMware and refreshes
# the JPG wallpaper and Polybar after a real display-size change.

WALLPAPER="$HOME/.wallpaper/wallpaper.jpg"
LOG="/tmp/0x0ps-vmware-resize.log"

while true; do
    INFO=$(xrandr --query 2>/dev/null)

    OUTPUT=$(printf '%s\n' "$INFO" | awk '
        $2 == "connected" && $1 ~ /^Virtual-/ {
            print $1
            exit
        }
    ')

    if [[ -n "$OUTPUT" ]]; then
        MODE=$(printf '%s\n' "$INFO" | awk -v out="$OUTPUT" '
            $1 == out && $2 == "connected" { found=1; next }
            found && /^[^[:space:]]/ { exit }
            found && $1 ~ /^[0-9]+x[0-9]+$/ && /\+/ {
                gsub(/[+*]/, "", $1)
                print $1
                exit
            }
        ')

        CURRENT=$(printf '%s\n' "$INFO" | awk -v out="$OUTPUT" '
            $1 == out && $2 == "connected" {
                for (i=1; i<=NF; i++) {
                    if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
                        split($i, a, "+")
                        print a[1]
                        exit
                    }
                }
            }
        ')

        if [[ -n "$MODE" && -n "$CURRENT" && "$MODE" != "$CURRENT" ]]; then
            echo "$(date): $OUTPUT $CURRENT -> $MODE" >> "$LOG"

            if xrandr --output "$OUTPUT" --mode "$MODE"; then
                sleep 1
                if [[ -f "$WALLPAPER" ]]; then
                    feh --no-fehbg --bg-fill "$WALLPAPER"
                fi
                polybar-msg cmd restart >/dev/null 2>&1
            fi
        fi
    fi

    sleep 2
done
