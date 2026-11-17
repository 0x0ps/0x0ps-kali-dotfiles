#!/bin/sh
# Display the IPv4 address of the interface carrying the default route.
IFACE=""
ADDRESS=""
if command -v ip >/dev/null 2>&1; then
    IFACE=$(ip -4 route show default 2>/dev/null | awk 'NR==1 {for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')
    ADDRESS=$(ip -o -4 addr show dev "$IFACE" scope global 2>/dev/null | awk 'NR==1 {split($4,a,"/"); print a[1]}')
fi
if [ -n "$ADDRESS" ]; then
    printf '%%{F#1bbf3e} %%{F#ffffff}%s%%{u-}\n' "$ADDRESS"
else
    printf '%%{F#2495e7}%%{u-} %%{F#ffffff}Disconnected\n'
fi
