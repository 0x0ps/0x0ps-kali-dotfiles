#!/usr/bin/env bash

# 0x0ps - ARTEX AI installer
# Installs the official ARTEX Docker deployment under ~/Opt/AI/ARTEX.
# Run from the repository root with: sudo ./install-artex.sh

set -Eeuo pipefail

log()  { printf '\n\033[1;36m[+] %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }

trap 'die "Installation failed at line $LINENO. Command: $BASH_COMMAND"' ERR

[[ "$EUID" -eq 0 ]] || die "Run with: sudo ./install-artex.sh"

ACTUAL_USER="${SUDO_USER:-}"
[[ -n "$ACTUAL_USER" && "$ACTUAL_USER" != "root" ]] ||
    die "Could not determine the normal desktop user."

USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"
[[ -d "$USER_HOME" ]] || die "Home directory not found for $ACTUAL_USER."

AI_DIR="$USER_HOME/Opt/AI"
ARTEX_DIR="$AI_DIR/ARTEX"

export DEBIAN_FRONTEND=noninteractive

log "Checking Docker and Git dependencies"

if ! command -v git >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    apt-get update
    apt-get install -y git curl ca-certificates openssl python3
fi

if ! command -v docker >/dev/null 2>&1; then
    apt-get update
    apt-get install -y docker.io docker-compose-v2 openssl python3
fi

if ! docker compose version >/dev/null 2>&1; then
    apt-get update
    apt-get install -y docker-compose-v2 openssl python3
fi

command -v docker >/dev/null 2>&1 || die "Docker is not installed."
docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required."

log "Enabling Docker service and desktop-user access"

getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker "$ACTUAL_USER"
systemctl enable --now docker

log "Preparing $ARTEX_DIR"

install -d -m 0755 -o "$ACTUAL_USER" -g "$(id -gn "$ACTUAL_USER")" "$AI_DIR"

if [[ -d "$ARTEX_DIR/.git" ]]; then
    log "Existing ARTEX source checkout found; keeping it in place"
elif [[ -e "$ARTEX_DIR" ]]; then
    die "$ARTEX_DIR already exists but is not an ARTEX Git checkout. Move it aside before installing."
else
    sudo -u "$ACTUAL_USER" -H git clone --depth 1 https://github.com/AA8Corp/artex.git "$ARTEX_DIR"
fi

[[ -f "$ARTEX_DIR/docker-compose.yml" ]] ||
    die "Official ARTEX docker-compose.yml was not found."
[[ -f "$ARTEX_DIR/.env.example" ]] ||
    die "Official ARTEX .env.example was not found."

log "Creating local ARTEX environment"

if [[ ! -f "$ARTEX_DIR/.env" ]]; then
    cp "$ARTEX_DIR/.env.example" "$ARTEX_DIR/.env"
    ARTEX_DB_PASSWORD="$(openssl rand -hex 32)"
    python3 - "$ARTEX_DIR/.env" "$ARTEX_DB_PASSWORD" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
password = sys.argv[2]
text = path.read_text(encoding="utf-8")
lines = []
for line in text.splitlines():
    if line.startswith("POSTGRES_PASSWORD="):
        line = f"POSTGRES_PASSWORD={password}"
    lines.append(line)
path.write_text("\n".join(lines) + "\n", encoding="utf-8")
PY
    chmod 600 "$ARTEX_DIR/.env"
else
    warn "Existing .env found: preserving its settings and credentials."
    chmod 600 "$ARTEX_DIR/.env"
fi

log "Restricting ARTEX web interfaces to localhost"

# The upstream Compose file publishes port 8787 on every interface.
# Keep the dashboard and auxiliary port reachable only from this Kali host.
python3 - "$ARTEX_DIR/docker-compose.yml" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = '      - "8787:8787"'
new = '      - "127.0.0.1:8787:8787"'
if old in text:
    text = text.replace(old, new, 1)
elif new not in text:
    raise SystemExit("Could not safely identify ARTEX port 8787 mapping; refusing to continue.")
path.write_text(text, encoding="utf-8")
PY

install -d -m 0755 -o "$ACTUAL_USER" -g "$(id -gn "$ACTUAL_USER")" \
    "$ARTEX_DIR/data" "$ARTEX_DIR/skills"
chown "$ACTUAL_USER:$(id -gn "$ACTUAL_USER")" "$ARTEX_DIR/.env"

log "Pulling official ARTEX images"
cd "$ARTEX_DIR"
docker compose pull

log "Starting ARTEX and PostgreSQL"
docker compose up -d

log "Checking container status"
docker compose ps

cat <<EOF

ARTEX installation completed.

Dashboard:    http://127.0.0.1:8787
Install path: $ARTEX_DIR
Config file:  $ARTEX_DIR/.env

Useful commands:
  cd "$ARTEX_DIR"
  sudo docker compose ps
  sudo docker compose logs -f artex
  sudo docker compose stop
  sudo docker compose up -d

The dashboard is bound to localhost and is not exposed to your LAN.
ARTEX is an autonomous security-testing tool: use it only in your own
lab or against systems for which you have explicit authorization.

The user was added to the docker group. Log out of Kali and back in
before using Docker without sudo. The docker group grants root-level
control over the host.
EOF
