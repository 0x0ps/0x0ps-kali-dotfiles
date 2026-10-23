#!/bin/sh
# 0x0ps Kali Dotfiles - adaptive SPICE resolution for i3
# Works with QXL/SPICE outputs named Virtual-*, without hardcoding a resolution.

WALLPAPER="$HOME/.wallpaper/wallpaper.png"
LAST_APPLIED=""

while :; do
    INFO=$(xrandr 2>/dev/null)

    # Only manage a virtual output (typical QXL/SPICE: Virtual-1).
    OUTPUT=$(printf '%s\n' "$INFO" | awk '
        $2 == "connected" && $1 ~ /^Virtual-/ { print $1; exit }
    ')

    if [ -n "$OUTPUT" ]; then
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
                for (i=1; i<=NF; i++)
                    if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) {
                        split($i, a, "+")
                        print a[1]
                        exit
                    }
            }
        ')

        if [ -n "$MODE" ] && [ -n "$CURRENT" ]; then
            if [ "$MODE" != "$CURRENT" ] && [ "$MODE" != "$LAST_APPLIED" ]; then
                # Let SPICE finish resizing before applying the new preferred mode.
                sleep 2
                NEW_MODE=$(xrandr 2>/dev/null | awk -v out="$OUTPUT" '
                    $1 == out && $2 == "connected" { found=1; next }
                    found && /^[^[:space:]]/ { exit }
                    found && $1 ~ /^[0-9]+x[0-9]+$/ && /\+/ {
                        gsub(/[+*]/, "", $1)
                        print $1
                        exit
                    }
                ')

                if [ -n "$NEW_MODE" ] && [ "$NEW_MODE" = "$MODE" ]; then
                    if xrandr --output "$OUTPUT" --mode "$MODE"; then
                        [ -f "$WALLPAPER" ] && feh --no-fehbg --bg-max "$WALLPAPER"
                        LAST_APPLIED="$MODE"
                    fi
                fi
            elif [ "$MODE" = "$CURRENT" ]; then
                LAST_APPLIED=""
            fi
        fi
    fi

    sleep 2
done
