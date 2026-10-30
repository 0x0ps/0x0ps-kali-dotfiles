#!/usr/bin/env bash

active=$(i3-msg -t get_workspaces | python3 -c '
import json,sys
for w in json.load(sys.stdin):
    if w["focused"]:
        print(w.get("num", -1))
        break
')

for n in {1..9}; do
    if [[ "$n" == "$active" ]]; then
        printf '%%{A1:i3-msg workspace number %s:}%%{T3}%%{F#A6FF00}☠%%{T-}%%{F-}%%{A}  ' "$n"
    else
        printf '%%{A1:i3-msg workspace number %s:}%%{F#FFFFFF} %s %%{F-}%%{A}' "$n" "$n"
    fi
done
printf '\n'
