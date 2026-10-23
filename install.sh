#!/usr/bin/env bash

# 0x0ps Kali Dotfiles - installer per Kali Linux 2026.x
#
#   sudo ./install.sh
#
# Differenze rispetto all'originale:
#   - kitty al posto di alacritty
#   - niente build di i3-gaps (i3 4.25 da apt ha già i gaps)
#   - ownership corretta fin dall'inizio (bug TPM "Permission denied")
#   - pywal solo via `uv tool install`
#   - dconf load con bus utente esplicito

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# ---------- Helpers ----------

log()  { printf '\n\033[1;36m[+] %s\033[0m\n' "$*"; }
warn() { printf '\n\033[1;33m[!] %s\033[0m\n' "$*"; }
die()  { printf '\n\033[1;31m[ERROR] %s\033[0m\n' "$*" >&2; exit 1; }

trap 'die "Installation failed at line $LINENO. Command: $BASH_COMMAND"' ERR

# ---------- Root / real user ----------

[[ "${EUID}" -eq 0 ]] || die "Run this installer with sudo: sudo ./install.sh"

if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    ACTUAL_USER="$SUDO_USER"
else
    ACTUAL_USER="$(logname 2>/dev/null || true)"
fi

[[ -n "${ACTUAL_USER:-}" && "$ACTUAL_USER" != "root" ]] || die "Could not determine the normal desktop user."

USER_HOME="$(getent passwd "$ACTUAL_USER" | cut -d: -f6)"
[[ -d "$USER_HOME" ]] || die "Could not determine home directory for $ACTUAL_USER."
USER_UID="$(id -u "$ACTUAL_USER")"

run_as_user() {
    sudo -u "$ACTUAL_USER" -H "$@"
}

# chown -R tollerante: salta i path inesistenti (con set -e un chown su
# path mancante ammazzerebbe lo script)
fix_owner() {
    local p
    for p in "$@"; do
        if [[ -e "$p" || -L "$p" ]]; then
            chown -R "$ACTUAL_USER:$ACTUAL_USER" "$p"
        fi
    done
    return 0
}

# ---------- Sanity checks ----------

log "Checking Kali environment"

[[ -f /etc/os-release ]] || die "/etc/os-release not found."
. /etc/os-release

if [[ "${ID:-}" != "kali" ]]; then
    warn "This installer was designed for Kali Linux. Detected: ${PRETTY_NAME:-unknown}"
fi

[[ -d "$SCRIPT_DIR/config" ]] || die "Missing config directory."

cd "$SCRIPT_DIR"

export DEBIAN_FRONTEND=noninteractive

# ---------- Packages ----------

log "Updating APT"
apt-get update

log "Installing 0x0ps dependencies"

# i3-wm 4.25 include i gaps: niente build da sorgente, quindi niente dev libs xcb/yajl/pcre2.
apt-get install -y \
    arandr \
    flameshot \
    arc-theme \
    feh \
    i3blocks \
    i3status \
    i3 \
    i3-wm \
    lxappearance \
    python3-pip \
    python3-venv \
    rofi \
    unclutter \
    cargo \
    compton \
    papirus-icon-theme \
    imagemagick \
    terminator \
    mpv \
    wget \
    curl \
    zsh \
    polybar \
    net-tools \
    kitty \
    tmux \
    xclip \
    pkg-config \
    gnome-terminal \
    dconf-cli \
    git \
    unzip \
    fontconfig \
    build-essential \
    xterm

# kitty come x-terminal-emulator (non fatale)
if [[ -x /usr/bin/kitty ]]; then
    update-alternatives --set x-terminal-emulator /usr/bin/kitty 2>/dev/null || \
        warn "Could not set kitty as x-terminal-emulator (non fatal)."
fi

# ---------- Directory utente (create come utente, non come root) ----------

log "Preparing user directories"

# Sistema eventuali dir root-owned lasciate da run precedenti falliti
fix_owner \
    "$USER_HOME/.tmux" \
    "$USER_HOME/.tmux-themepack" \
    "$USER_HOME/.local" \
    "$USER_HOME/.fonts" \
    "$USER_HOME/.config" \
    "$USER_HOME/.cache"

CACHE_DIR="$USER_HOME/.cache/0x0ps"
FONT_DIR="$USER_HOME/.local/share/fonts"
LEGACY_FONT_DIR="$USER_HOME/.fonts"

run_as_user mkdir -p \
    "$CACHE_DIR" \
    "$FONT_DIR" \
    "$LEGACY_FONT_DIR" \
    "$USER_HOME/.config/i3" \
    "$USER_HOME/.config/compton" \
    "$USER_HOME/.config/rofi" \
    "$USER_HOME/.config/kitty" \
    "$USER_HOME/.config/polybar" \
    "$USER_HOME/.config/terminator"

# ---------- uv + pywal ----------

log "Installing/updating uv for $ACTUAL_USER"

run_as_user bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

UV_BIN=""
for candidate in "$USER_HOME/.local/bin/uv" "$USER_HOME/.cargo/bin/uv"; do
    if [[ -x "$candidate" ]]; then
        UV_BIN="$candidate"
        break
    fi
done

if [[ -n "$UV_BIN" ]]; then
    log "Installing pywal with uv"
    run_as_user "$UV_BIN" tool install pywal
else
    warn "uv executable not found. Skipping pywal installation."
fi

# ---------- Fonts ----------

install_zip_font() {
    local url="$1" archive="$2" destination="$3"

    log "Installing font archive: $archive"

    if [[ ! -s "$CACHE_DIR/$archive" ]]; then
        run_as_user curl -fL "$url" -o "$CACHE_DIR/$archive"
    else
        log "$archive already cached; reusing it."
    fi

    run_as_user unzip -o "$CACHE_DIR/$archive" -d "$destination" >/dev/null
}

install_zip_font \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/Iosevka.zip" \
    "Iosevka.zip" "$FONT_DIR"

install_zip_font \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/RobotoMono.zip" \
    "RobotoMono.zip" "$FONT_DIR"

install_zip_font \
    "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip" \
    "Hack.zip" "$LEGACY_FONT_DIR"

run_as_user fc-cache -f

# ---------- Shell (zsh) / tmux ----------

log "Installing zsh and tmux configuration"

# .tmux.conf dai dotfiles
install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
    "$SCRIPT_DIR/config/.tmux.conf" "$USER_HOME/.tmux.conf"

# .zshrc: NON sovrascriviamo quello di Kali (prompt, alias, colori, completion),
# gestiamo solo un blocco marcato e idempotente con PATH / bun / nvm / history.
ZSHRC="$USER_HOME/.zshrc"

if [[ ! -f "$ZSHRC" ]]; then
    if [[ -f /etc/skel/.zshrc ]]; then
        install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" /etc/skel/.zshrc "$ZSHRC"
    else
        run_as_user touch "$ZSHRC"
    fi
fi

cp -a "$ZSHRC" "$ZSHRC.bak"

# rimuove l'eventuale blocco precedente, poi lo riscrive
sed -i '/^# >>> zerodaygym >>>$/,/^# <<< zerodaygym <<<$/d' "$ZSHRC"
sed -i '/^# >>> 0x0ps >>>$/,/^# <<< 0x0ps <<</d' "$ZSHRC"
cat >> "$ZSHRC" <<'ZSHBLOCK'
# >>> 0x0ps >>>
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"

export BUN_INSTALL="$HOME/.bun"
[ -d "$BUN_INSTALL/bin" ] && export PATH="$BUN_INSTALL/bin:$PATH"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# cronologia condivisa tra le sessioni
setopt inc_append_history share_history

# Funzione per impostare e rimuovere il Target in Polybar
target() {
    if [ -z "$1" ]; then
        echo "Uso: target <IP>"
    else
        echo "$1" > "$HOME/.config/bin/target"
        echo "Target impostato su: $1"
    fi
}

cleartarget() {
    echo "" > "$HOME/.config/bin/target"
    echo "Target rimosso"
}

# >>> 0x0ps Matrix Prompt >>>
autoload -Uz colors && colors
PROMPT='%F{green}┌──(%F{green}%n%F{cyan}㉿%F{cyan}%m%F{green})-[%F{yellow}%~%F{green}]%f
%F{red}└─%F{green}❯%f '
# <<< 0x0ps Matrix Prompt <<<

# <<< 0x0ps <<<
ZSHBLOCK

chown "$ACTUAL_USER:$ACTUAL_USER" "$ZSHRC" "$ZSHRC.bak"

# ---------- TPM ----------

log "Installing TPM"

run_as_user mkdir -p "$USER_HOME/.tmux/plugins"

if [[ -d "$USER_HOME/.tmux/plugins/tpm/.git" ]]; then
    run_as_user git -C "$USER_HOME/.tmux/plugins/tpm" pull --ff-only
else
    rm -rf "$USER_HOME/.tmux/plugins/tpm"
    run_as_user git clone https://github.com/tmux-plugins/tpm \
        "$USER_HOME/.tmux/plugins/tpm"
fi

# ---------- tmux-themepack ----------

log "Installing tmux-themepack"

if [[ -d "$USER_HOME/.tmux-themepack/.git" ]]; then
    run_as_user git -C "$USER_HOME/.tmux-themepack" pull --ff-only
else
    rm -rf "$USER_HOME/.tmux-themepack"
    run_as_user git clone https://github.com/jimeh/tmux-themepack.git \
        "$USER_HOME/.tmux-themepack"
fi

# ---------- Configuration ----------

log "Installing 0x0ps configuration"

copy_if_exists() {
    local source="$1" destination="$2"
    if [[ -e "$source" ]]; then
        cp -a "$source" "$destination"
    else
        warn "Missing source: $source"
    fi
}

copy_if_exists "$SCRIPT_DIR/config/nvim" "$USER_HOME/.config/"
copy_if_exists "$SCRIPT_DIR/config/bin"  "$USER_HOME/.config/"

# kitty: copia tutto il contenuto della dir (merge, non annida)
if [[ -d "$SCRIPT_DIR/config/kitty" ]]; then
    cp -a "$SCRIPT_DIR/config/kitty/." "$USER_HOME/.config/kitty/"
else
    warn "Missing source: $SCRIPT_DIR/config/kitty"
fi

# wallpaper: idem, evita ~/.wallpaper/wallpaper se la dir esiste già
if [[ -d "$SCRIPT_DIR/wallpaper" ]]; then
    mkdir -p "$USER_HOME/.wallpaper"
    cp -a "$SCRIPT_DIR/wallpaper/." "$USER_HOME/.wallpaper/"
else
    warn "Missing source: $SCRIPT_DIR/wallpaper"
fi

copy_if_exists "$SCRIPT_DIR/config/terminator/config"    "$USER_HOME/.config/terminator/config"

copy_if_exists "$SCRIPT_DIR/config/i3/config"            "$USER_HOME/.config/i3/config"
copy_if_exists "$SCRIPT_DIR/config/i3/i3blocks.conf"     "$USER_HOME/.config/i3/i3blocks.conf"
copy_if_exists "$SCRIPT_DIR/config/i3/clipboard_fix.sh"  "$USER_HOME/.config/i3/clipboard_fix.sh"
copy_if_exists "$SCRIPT_DIR/config/compton/compton.conf" "$USER_HOME/.config/compton/compton.conf"
copy_if_exists "$SCRIPT_DIR/config/rofi/config"          "$USER_HOME/.config/rofi/config"

if [[ -d "$SCRIPT_DIR/config/polybar" ]]; then
    cp -a "$SCRIPT_DIR/config/polybar/." "$USER_HOME/.config/polybar/"
fi

copy_if_exists "$SCRIPT_DIR/fehbg" "$USER_HOME/.fehbg"

# i3: layout e script personalizzato per Kitty a tre pannelli
if [[ -d "$SCRIPT_DIR/config/i3/layouts" ]]; then
    mkdir -p "$USER_HOME/.config/i3/layouts"
    cp -a "$SCRIPT_DIR/config/i3/layouts/." "$USER_HOME/.config/i3/layouts/"
fi

if [[ -d "$SCRIPT_DIR/config/i3/scripts" ]]; then
    mkdir -p "$USER_HOME/.config/i3/scripts"
    cp -a "$SCRIPT_DIR/config/i3/scripts/." "$USER_HOME/.config/i3/scripts/"
fi

# ---------- Permissions ----------

log "Fixing executable permissions"

if [[ -d "$USER_HOME/.config/bin" ]]; then
    find "$USER_HOME/.config/bin" -type f -exec chmod +x {} +
fi

for f in \
    "$USER_HOME/.config/polybar/launch.sh" \
    "$USER_HOME/.config/i3/clipboard_fix.sh" \
    "$USER_HOME/.config/i3/scripts/kitty-3pane.sh" \
    "$USER_HOME/.fehbg"
do
    if [[ -f "$f" ]]; then chmod +x "$f"; fi
done

# ---------- Rofi theme ----------

log "Installing Nord Rofi theme"

ROFI_THEME_URL="https://raw.githubusercontent.com/undiabler/nord-rofi-theme/master/nord.rasi"
ROFI_THEME_DIR="/usr/share/rofi/themes"

mkdir -p "$ROFI_THEME_DIR"
curl -fL "$ROFI_THEME_URL" -o "$ROFI_THEME_DIR/nord.rasi" || \
    warn "Could not download Nord rofi theme (non fatal)."

# ---------- Ownership (rete di sicurezza) ----------

log "Fixing ownership"

fix_owner \
    "$USER_HOME/.config" \
    "$USER_HOME/.local" \
    "$USER_HOME/.cache/0x0ops" \
    "$USER_HOME/.fonts" \
    "$USER_HOME/.tmux" \
    "$USER_HOME/.tmux-themepack" \
    "$USER_HOME/.wallpaper" \
    "$USER_HOME/.zshrc" \
    "$USER_HOME/.zshrc.bak" \
    "$USER_HOME/.tmux.conf" \
    "$USER_HOME/.fehbg"

# ---------- GNOME Terminal (dconf) ----------

# ---------- GNOME Terminal (dconf) ----------

GNOME_BACKUP="$SCRIPT_DIR/config/gnome_terminal_settings_backup.txt"

if [[ -f "$GNOME_BACKUP" ]]; then
    log "Restoring GNOME Terminal configuration"

    USER_BUS="/run/user/$USER_UID/bus"

    if [[ -S "$USER_BUS" ]]; then
        run_as_user env \
            XDG_RUNTIME_DIR="/run/user/$USER_UID" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
            dconf load /org/gnome/terminal/ < "$GNOME_BACKUP" || \
            warn "dconf load failed."
    else
        warn "No user session bus. GNOME Terminal settings restore skipped."
    fi
else
    warn "GNOME Terminal backup not found; skipping settings restore."
fi
# ---------- Summary ----------

log "Installation completed"

cat <<EOF

============================================================
 0x0ps Kali installer finished
============================================================

User:    $ACTUAL_USER
Home:    $USER_HOME
Source:  $SCRIPT_DIR

Next steps:
  1. Logout/login e seleziona i3 al login screen.
  2. Apri una nuova shell zsh (o: source ~/.zshrc) per avere wal nel PATH.
  3. Valida il config i3:  i3 -C -c ~/.config/i3/config
  4. Nel config i3 sostituisci i riferimenti al vecchio terminale:
       grep -nE 'alacritty|terminator' ~/.config/i3/config
     con "kitty".
  5. tmux: apri tmux e premi prefix + I per installare i plugin TPM.
  6. lxappearance per il tema GTK se serve.

Backup del .zshrc precedente: ~/.zshrc.bak
============================================================
EOF
