#!/usr/bin/env bash
# 0x0ps: disable X11 blanking/DPMS and request the Performance power profile.
# Run from the user's i3 session so DISPLAY and the X session are available.

set -u

log() { printf '[0x0ps-power] %s\n' "$*"; }

if command -v xset >/dev/null 2>&1 && [[ -n "${DISPLAY:-}" ]]; then
    xset s off
    xset s noblank
    xset -dpms
    log "X11 screensaver, screen blanking and DPMS disabled."
else
    log "X11 session not detected; skipping xset settings."
fi

if command -v powerprofilesctl >/dev/null 2>&1; then
    if powerprofilesctl set performance >/dev/null 2>&1; then
        log "Performance power profile enabled."
    else
        log "Performance profile is not exposed by this hardware/virtual machine."
    fi
else
    log "powerprofilesctl not available; leaving CPU profile unchanged."
fi
