#!/usr/bin/env bash
# 0x0ps optional ARTEX installer.
# Installs the upstream ARTEX project under "$HOME/Opt/AI/ARTEX".
# Run as the normal desktop user, NOT with sudo.

set -Eeuo pipefail

APP_REPO="https://github.com/BaaRai/ARTEX.git"
INSTALL_DIR="$HOME/Opt/AI/ARTEX"

log()  { printf '\n\033[1;36m[+] %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }
trap 'die "ARTEX installation failed at line $LINENO. Command: $BASH_COMMAND"' ERR

[[ "$EUID" -ne 0 ]] || die "Run as your normal desktop user, without sudo."
[[ -n "${HOME:-}" && "$HOME" != "/" ]] || die "Could not determine a valid user home directory."

for cmd in git docker openssl; do
    command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

docker compose version >/dev/null 2>&1 || die "Docker Compose v2 is required."
docker info >/dev/null 2>&1 || die "Docker is not accessible to this user. Install Docker and ensure your user can run docker commands, then log out and back in."

git_clone_retry() {
    local attempt
    for attempt in 1 2 3; do
        if git clone --depth 1 "$APP_REPO" "$INSTALL_DIR"; then
            return 0
        fi
        rm -rf "$INSTALL_DIR"
        if [[ "$attempt" -lt 3 ]]; then
            warn "ARTEX clone failed (attempt $attempt/3); retrying."
            sleep "$((attempt * 3))"
        fi
    done
    return 1
}

log "Preparing ARTEX installation directory"
mkdir -p "$HOME/Opt/AI"

if [[ -d "$INSTALL_DIR/.git" ]]; then
    log "Existing ARTEX checkout found"
    read -r -p "Update this checkout with git pull --ff-only? [y/N]: " answer
    case "$answer" in
        [yY]|[yY][eE][sS])
            git -C "$INSTALL_DIR" pull --ff-only
            ;;
        *)
            log "Keeping the existing ARTEX source checkout."
            ;;
    esac
elif [[ -e "$INSTALL_DIR" ]]; then
    die "$INSTALL_DIR exists but is not a Git checkout. Move it aside before installing."
else
    log "Cloning the official English ARTEX repository"
    git_clone_retry
fi

cd "$INSTALL_DIR"
[[ -f .env.example ]] || die "The ARTEX checkout does not contain .env.example."
[[ -f docker-compose.yml ]] || die "The ARTEX checkout does not contain docker-compose.yml."

if [[ ! -f .env ]]; then
    log "Creating a private Docker Compose environment file"
    cp .env.example .env
    DB_PASSWORD="$(openssl rand -hex 32)"
    if grep -q '^POSTGRES_PASSWORD=' .env; then
        sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$DB_PASSWORD/" .env
    else
        printf '\nPOSTGRES_PASSWORD=%s\n' "$DB_PASSWORD" >> .env
    fi
else
    log "Existing .env found; preserving database credentials and LLM settings."
fi

# Never expose the web UI or traffic proxy on every network interface by default.
if grep -q '^ARTEX_BIND_ADDR=' .env; then
    sed -i 's/^ARTEX_BIND_ADDR=.*/ARTEX_BIND_ADDR=127.0.0.1/' .env
else
    printf '\nARTEX_BIND_ADDR=127.0.0.1\n' >> .env
fi
chmod 600 .env

# Keep persistent bind-mount directories present and owned by the installing user.
mkdir -p data keys
chmod 700 keys

log "Validating ARTEX Compose configuration"
docker compose config -q

log "Building ARTEX and starting ARTEX + PostgreSQL"
docker compose up -d --build

log "Checking running services"
docker compose ps

cat <<'INFO'

============================================================
 ARTEX installation prepared
============================================================

Location:  $INSTALL_DIR
Web UI:    http://127.0.0.1:8787
Proxy:     127.0.0.1:8788 (local only)

The web UI is bound to loopback. It is not exposed to your LAN
or the Internet by this installer.

First-time setup:
  1. Read the setup token:
     cd "$INSTALL_DIR" && docker compose logs artex | grep "Setup token"
  2. Open http://127.0.0.1:8787 and complete /setup.
  3. Configure an LLM provider in ARTEX System settings.
     Exploration requires an LLM; API keys can be entered in the UI.

Useful commands:
  Start:   cd "$INSTALL_DIR" && docker compose up -d
  Stop:    cd "$INSTALL_DIR" && docker compose stop
  Logs:    cd "$INSTALL_DIR" && docker compose logs -f
  Update:  cd "$INSTALL_DIR" && git pull --ff-only && docker compose up -d --build

The PostgreSQL password is stored in $INSTALL_DIR/.env (mode 600).
Keep .env, keys/ and data/ private and include them in secure backups.
============================================================
INFO
