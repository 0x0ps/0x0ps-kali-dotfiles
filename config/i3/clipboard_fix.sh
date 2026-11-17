#!/usr/bin/env bash
# Optional VMware clipboard helper. Safe on non-VMware systems.
if ! command -v vmtoolsd >/dev/null 2>&1; then exit 0; fi
pkill -x vmtoolsd 2>/dev/null || true
exec vmtoolsd -n vmusr
