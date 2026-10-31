#!/usr/bin/env bash

# 0x0ps - BloodHound Community Edition Installer

set -Eeuo pipefail

log() {
    printf '\n\033[1;36m[+] %s\033[0m\n' "$*"
}

die() {
    printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2
    exit 1
}

trap 'die "Installation failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# Require root, but execute BloodHound as the desktop user.
[[ "$EUID" -eq 0 ]] || die "Run with: sudo ./install-bloodhound.sh"

ACTUAL_USER="${SUDO_USER:-}"
[[ -n "$ACTUAL_USER" && "$ACTUAL_USER" != "root" ]] ||
    die "Could not determine the normal desktop user."

USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"
[[ -d "$USER_HOME" ]] || die "User home directory not found."

run_as_user() {
    sudo -u "$ACTUAL_USER" -H "$@"
}

export DEBIAN_FRONTEND=noninteractive

log "Checking architecture"

BH_CPU_ARCH="$(dpkg --print-architecture)"

case "$BH_CPU_ARCH" in
    amd64) BH_CLI_PLATFORM="amd64" ;;
    arm64) BH_CLI_PLATFORM="arm64" ;;
    *) die "Unsupported architecture: $BH_CPU_ARCH" ;;
esac

log "Installing Docker and required dependencies"

apt-get update

if ! command -v docker >/dev/null 2>&1 || \
   ! systemctl cat docker.service >/dev/null 2>&1; then
    apt-get install -y docker.io
fi

if ! docker compose version >/dev/null 2>&1; then
    apt-get install -y docker-compose
fi

apt-get install -y curl ca-certificates

command -v docker >/dev/null 2>&1 ||
    die "Docker installation failed."

docker compose version >/dev/null 2>&1 ||
    die "Docker Compose v2 is required."

log "Enabling Docker"

getent group docker >/dev/null 2>&1 || groupadd docker
usermod -aG docker "$ACTUAL_USER"

systemctl enable --now docker

run_as_user docker info >/dev/null 2>&1 ||
    die "Docker is not accessible by $ACTUAL_USER."

log "Downloading official BloodHound CLI"

BH_CLI_URL="https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-${BH_CLI_PLATFORM}.tar.gz"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fL --retry 3 "$BH_CLI_URL" \
    -o "$TMP_DIR/bloodhound-cli.tar.gz"

tar -xzf "$TMP_DIR/bloodhound-cli.tar.gz" -C "$TMP_DIR"

BH_CLI_BIN="$(find "$TMP_DIR" -type f -name bloodhound-cli -print -quit)"

[[ -n "$BH_CLI_BIN" ]] ||
    die "BloodHound CLI binary not found in archive."

install -m 0755 "$BH_CLI_BIN" /usr/local/bin/bloodhound-cli

log "Preparing BloodHound configuration"

BHCE_DIR="$USER_HOME/.config/bloodhound"
XDG_CONFIG_HOME="$USER_HOME/.config"

run_as_user mkdir -p "$BHCE_DIR"

BH_ENV=(
    env
    "XDG_CONFIG_HOME=$XDG_CONFIG_HOME"
    "PATH=/usr/local/bin:$USER_HOME/.local/bin:/usr/bin:/bin"
)

if [[ -f "$BHCE_DIR/docker-compose.yml" ]]; then
    log "Existing BloodHound CE installation found: updating"
    run_as_user "${BH_ENV[@]}" bloodhound-cli update
else
    log "Installing BloodHound Community Edition"
    log "IMPORTANT: save the generated admin password."
    run_as_user "${BH_ENV[@]}" bloodhound-cli install
fi

log "BloodHound CE installation completed."
log "Web interface: http://localhost:8080/ui/login"
log "Username: admin"
log "Configuration: $BHCE_DIR"

cat <<'MSG'

IMPORTANT:
The docker group grants privileges equivalent to root.
A new login session may be required for your normal shell
to recognize the new group membership.

MSG
