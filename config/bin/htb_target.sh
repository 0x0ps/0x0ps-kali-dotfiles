#!/bin/sh
TARGET_FILE="$HOME/.config/bin/target"
ip_target=""
name_target=""
if [ -r "$TARGET_FILE" ]; then
    read -r ip_target name_target < "$TARGET_FILE" || true
fi
if [ -n "$ip_target" ] && [ -n "$name_target" ]; then
    printf '%%{F#cf9fff}什%%{F#ffffff} %s - %s\n' "$ip_target" "$name_target"
elif [ -n "$ip_target" ]; then
    printf '%%{F#cf9fff}什%%{F#ffffff} %s\n' "$ip_target"
else
    printf '%%{F#cf9fff}ﲅ %%{u-}%%{F#ffffff} No target\n'
fi
