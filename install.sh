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

# ---------- System update ----------

log "Refreshing APT package indexes"
apt-get update

log "Applying full Kali Linux system upgrade"
apt-get full-upgrade -y

# ---------- Packages ----------

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
    picom \
    fastfetch \
    lsd \
    bat \
    fzf \
    fd-find \
    btop \
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
    xterm \
    spice-vdagent

# Fastfetch is required by the custom configuration and the Zsh startup hook.
command -v fastfetch >/dev/null 2>&1 || die "Fastfetch installation failed."

# kitty come x-terminal-emulator (non fatale)
if [[ -x /usr/bin/kitty ]]; then
    update-alternatives --set x-terminal-emulator /usr/bin/kitty 2>/dev/null || \
        warn "Could not set kitty as x-terminal-emulator (non fatal)."
fi

# ---------- Firefox theme: Cyberpunk Neon Rain ----------

log "Configuring the Cyberpunk theme for Firefox"

FIREFOX_BIN=""
for candidate in firefox-esr firefox; do
    if command -v "$candidate" >/dev/null 2>&1; then
        FIREFOX_BIN="$(command -v "$candidate")"
        break
    fi
done

if [[ -n "$FIREFOX_BIN" ]]; then
    # Resolve the AMO add-on GUID from Mozilla's API, then use Firefox's
    # enterprise policy to install the theme for the normal desktop user.
    FIREFOX_THEME_GUID="$(python3 - <<'PY'
import json
import urllib.request

url = "https://addons.mozilla.org/api/v5/addons/addon/cyberpunk-neon-rain/"
request = urllib.request.Request(url, headers={"User-Agent": "0x0ps-Kali-Installer/1.0"})
with urllib.request.urlopen(request, timeout=20) as response:
    data = json.load(response)
guid = data.get("guid")
if not isinstance(guid, str) or not guid.strip():
    raise SystemExit("Mozilla AMO API did not return a valid add-on GUID.")
print(guid.strip())
PY
    )" || FIREFOX_THEME_GUID=""

    if [[ -n "$FIREFOX_THEME_GUID" ]]; then
        FIREFOX_POLICY_DIR="/etc/firefox/policies"
        FIREFOX_POLICY="$FIREFOX_POLICY_DIR/policies.json"
        install -d -m 0755 "$FIREFOX_POLICY_DIR"

        # Merge with an existing Firefox policy file instead of replacing it.
        python3 - "$FIREFOX_POLICY" "$FIREFOX_THEME_GUID" <<'PY'
import json
import os
import sys
import tempfile

path, guid = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path):
    with open(path, encoding="utf-8") as source:
        data = json.load(source)

policies = data.setdefault("policies", {})
settings = policies.setdefault("ExtensionSettings", {})
settings[guid] = {
    "installation_mode": "normal_installed",
    "install_url": "https://addons.mozilla.org/firefox/downloads/latest/cyberpunk-neon-rain/latest.xpi"
}

directory = os.path.dirname(path)
fd, temporary = tempfile.mkstemp(prefix=".policies-", dir=directory, text=True)
try:
    with os.fdopen(fd, "w", encoding="utf-8") as output:
        json.dump(data, output, indent=2)
        output.write("\n")
    os.chmod(temporary, 0o644)
    os.replace(temporary, path)
finally:
    if os.path.exists(temporary):
        os.unlink(temporary)
PY
        log "Firefox Cyberpunk theme policy installed. Firefox will apply it at next startup."
    else
        warn "Could not retrieve the Cyberpunk theme ID from Mozilla AMO; skipping automatic theme installation."
    fi
else
    warn "Firefox was not found; skipping Cyberpunk theme installation."
fi

# ---------- Slick Greeter / LightDM ----------

log "Configuring Slick Greeter and LightDM"

apt-get install -y \
    slick-greeter \
    lightdm \
    kali-themes \
    kali-themes-common \
    fonts-cantarell \
    libglib2.0-bin

# Installa lo stesso sfondo verificato sul sistema attuale.
LOGIN_WALLPAPER="$SCRIPT_DIR/wallpaper/wallpaper.jpg"
if [[ -f "$LOGIN_WALLPAPER" ]]; then
    install -D -m 0644 "$LOGIN_WALLPAPER" \
        /usr/share/backgrounds/0x0ps-login-wallpaper.jpg
else
    warn "Login wallpaper missing: $LOGIN_WALLPAPER"
fi

# Seleziona Slick Greeter e imposta i3 come sessione predefinita.
install -d -m 0755 /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/99-null0x-greeter.conf <<'EOF'
[Seat:*]
greeter-session=slick-greeter
user-session=i3
EOF

# Imposta i3 come sessione predefinita per l'utente.
DMRC="$USER_HOME/.dmrc"
if [[ -f "$DMRC" ]]; then
    TMP_DMRC="$(mktemp)"
    awk '
        /^\[/ {
            if (in_desktop && !found) print "Session=i3"
            in_desktop = ($0 == "[Desktop]")
            if (in_desktop) seen = 1
            print
            next
        }
        in_desktop && /^Session=/ {
            if (!found) print "Session=i3"
            found = 1
            next
        }
        { print }
        END {
            if (in_desktop && !found) print "Session=i3"
            if (!seen) {
                print ""
                print "[Desktop]"
                print "Session=i3"
            }
        }
    ' "$DMRC" > "$TMP_DMRC"
    cat "$TMP_DMRC" > "$DMRC"
    rm -f "$TMP_DMRC"
else
    printf '[Desktop]\nSession=i3\n' > "$DMRC"
fi

chown "$ACTUAL_USER":"$(id -gn "$ACTUAL_USER")" "$DMRC"


# Override locale separato dai file di configurazione dei pacchetti.
install -d -m 0755 /usr/share/glib-2.0/schemas
cat > /usr/share/glib-2.0/schemas/90_null0x-slick-greeter.gschema.override <<'EOF'
[x.dm.slick-greeter]
background='/usr/share/backgrounds/0x0ps-login-wallpaper.jpg'
background-color='#000000'
draw-user-backgrounds=false
draw-grid=false
theme-name='0x0PS-Greeter'
icon-theme-name='Flat-Remix-Green-Dark'
font-name='Cantarell 11'
show-clock=true
clock-format='%d %b, %H:%M'
show-hostname=false
show-keyboard=true
show-a11y=true
show-power=true
show-quit=true
activate-numlock=true
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

# Keep the greeter's explicit configuration aligned with the compiled settings.
install -d -m 0755 /etc/lightdm
if [[ -f /etc/lightdm/slick-greeter.conf ]]; then
    cp -a /etc/lightdm/slick-greeter.conf \
        "/etc/lightdm/slick-greeter.conf.bak.$(date +%Y%m%d%H%M%S)"
fi
# Build an independent GTK theme from Kali-Dark; never modify the vendor theme.
CUSTOM_GTK_THEME="/usr/share/themes/0x0PS-Greeter"
install -d -m 0755 "$CUSTOM_GTK_THEME"
cp -a /usr/share/themes/Kali-Dark/. "$CUSTOM_GTK_THEME/"
sed -i \
    -e 's/Name=Kali-Dark/Name=0x0PS-Greeter/' \
    -e 's/GtkTheme=Kali-Dark/GtkTheme=0x0PS-Greeter/' \
    "$CUSTOM_GTK_THEME/index.theme"

# Install the repository's neon overrides and import them once in both GTK stylesheets.
install -D -m 0644 "$SCRIPT_DIR/config/lightdm/0x0ps.css" \
    "$CUSTOM_GTK_THEME/gtk-3.0/0x0ps.css"
for gtk_css in "$CUSTOM_GTK_THEME/gtk-3.0/gtk.css" \
               "$CUSTOM_GTK_THEME/gtk-3.0/gtk-dark.css"; do
    if ! grep -Fq '@import url("0x0ps.css");' "$gtk_css"; then
        # GTK CSS imports must appear before the theme's other CSS rules.
        sed -i '1i @import url("0x0ps.css");' "$gtk_css"
    fi
done

cat > /etc/lightdm/slick-greeter.conf <<'GREETER'
[Greeter]
theme-name=0x0PS-Greeter
background=/usr/share/backgrounds/0x0ps-login-wallpaper.jpg
draw-user-background=false
GREETER

log "Slick Greeter configured. Reboot to apply the login-screen changes."

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
    "$USER_HOME/.config/terminator" \
    "$USER_HOME/.config/lsd" \
    "$USER_HOME/.config/bat" \
    "$USER_HOME/.config/fzf" \
    "$USER_HOME/.config/btop/themes"

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
    # Rendi uv e i tool installati visibili anche durante questa esecuzione,
    # senza dipendere dal PATH della shell che ha lanciato l'installer.
    run_as_user env PATH="$USER_HOME/.local/bin:$USER_HOME/.cargo/bin:$PATH" \
        "$UV_BIN" tool install pywal
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

# Custom 0x0ps Burp Suite icon font
BURP_FONT="$SCRIPT_DIR/fonts/0x0ps-burp-icons.ttf"
if [[ -f "$BURP_FONT" ]]; then
    install -D -m 0644 -o "$ACTUAL_USER" -g "$(id -gn "$ACTUAL_USER")" \
        "$BURP_FONT" "$FONT_DIR/0x0ps-burp-icons.ttf"
else
    warn "Custom Burp icon font missing: $BURP_FONT"
fi

run_as_user fc-cache -f

# ---------- Fastfetch ----------

log "Installing 0x0PS Fastfetch configuration"

FASTFETCH_CONFIG_DIR="$USER_HOME/.config/fastfetch"
FASTFETCH_CONFIG="$FASTFETCH_CONFIG_DIR/config.jsonc"
FASTFETCH_LOGO_SOURCE="$SCRIPT_DIR/assets/fastfetch/0x0ps.png"
FASTFETCH_LOGO_DEST="$FASTFETCH_CONFIG_DIR/0x0ps.png"

install -d -m 0755 "$FASTFETCH_CONFIG_DIR"

if [[ -f "$FASTFETCH_CONFIG" ]]; then
    cp -a "$FASTFETCH_CONFIG" "$FASTFETCH_CONFIG.bak.$(date +%Y%m%d%H%M%S)"
fi

if [[ -f "$SCRIPT_DIR/config/fastfetch/config.jsonc" ]]; then
    sed "s|@USER_HOME@|$USER_HOME|g" \
        "$SCRIPT_DIR/config/fastfetch/config.jsonc" > "$FASTFETCH_CONFIG"
    chown "$ACTUAL_USER:$ACTUAL_USER" "$FASTFETCH_CONFIG"
else
    warn "Fastfetch config template missing; keeping the existing configuration."
fi

if [[ -f "$FASTFETCH_LOGO_SOURCE" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$FASTFETCH_LOGO_SOURCE" "$FASTFETCH_LOGO_DEST"
else
    warn "0x0PS Fastfetch PNG missing: $FASTFETCH_LOGO_SOURCE"
    warn "Add assets/fastfetch/0x0ps.png to the repository and rerun the installer."
fi

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

# 0x0ps neon command-line palette
export LS_COLORS='di=38;2;166;255;0:ln=38;2;0;220;255:pi=38;2;0;220;255:so=38;2;0;220;255:bd=38;2;0;220;255:cd=38;2;0;220;255:ex=38;2;255;0;175:fi=38;2;255;255;255:or=38;2;255;0;0:mi=38;2;255;0;0'
export BAT_THEME="Monokai Extended"

alias ls='lsd --color=always'
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -lah --group-dirs=first'
alias lt='lsd --tree --depth=2'
alias lla='lsd -lah --group-dirs=first --git'

if command -v batcat >/dev/null 2>&1 && ! command -v bat >/dev/null 2>&1; then
    alias bat='batcat'
fi

# Load the version-controlled fzf palette and Zsh integration.
[[ -r "$HOME/.config/fzf/fzf.zsh" ]] && source "$HOME/.config/fzf/fzf.zsh"

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
PROMPT='%F{#A6FF00}┌──(%F{#A6FF00}%n%F{#00FFFF}㉿%F{#00FFFF}%m%F{#A6FF00})-[%F{#FFFFFF}%~%F{#A6FF00}]
%F{#A6FF00}└─❯%f '
# <<< 0x0ps Matrix Prompt <<<

# <<< 0x0ps <<<
ZSHBLOCK

chown "$ACTUAL_USER:$ACTUAL_USER" "$ZSHRC" "$ZSHRC.bak"

# ---------- Git neon colors and useful aliases ----------

log "Configuring Git colors and aliases"

GIT_CONFIG_SOURCE="$SCRIPT_DIR/config/gitconfig"
if [[ -f "$GIT_CONFIG_SOURCE" ]]; then
    while IFS= read -r entry; do
        [[ -n "$entry" ]] || continue
        key="${entry%%=*}"
        value="${entry#*=}"
        run_as_user git config --global --replace-all "$key" "$value"
    done < <(git config --file "$GIT_CONFIG_SOURCE" --list)
else
    warn "Git color config missing; skipping custom Git settings."
fi

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

# Neon CLI tools: version-controlled user configuration.
if [[ -f "$SCRIPT_DIR/config/lsd/config.yaml" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/lsd/config.yaml" "$USER_HOME/.config/lsd/config.yaml"
fi
if [[ -f "$SCRIPT_DIR/config/lsd/colors.yaml" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/lsd/colors.yaml" "$USER_HOME/.config/lsd/colors.yaml"
fi
if [[ -f "$SCRIPT_DIR/config/bat/config" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/bat/config" "$USER_HOME/.config/bat/config"
fi
if [[ -f "$SCRIPT_DIR/config/fzf/fzf.zsh" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/fzf/fzf.zsh" "$USER_HOME/.config/fzf/fzf.zsh"
fi
if [[ -f "$SCRIPT_DIR/config/btop/btop.conf" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/btop/btop.conf" "$USER_HOME/.config/btop/btop.conf"
fi
if [[ -f "$SCRIPT_DIR/config/btop/themes/0x0ps-neon.theme" ]]; then
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$SCRIPT_DIR/config/btop/themes/0x0ps-neon.theme" "$USER_HOME/.config/btop/themes/0x0ps-neon.theme"
fi

# kitty: copia tutto il contenuto della dir (merge, non annida)
if [[ -d "$SCRIPT_DIR/config/kitty" ]]; then
    cp -a "$SCRIPT_DIR/config/kitty/." "$USER_HOME/.config/kitty/"
else
    warn "Missing source: $SCRIPT_DIR/config/kitty"
fi

# wallpaper: copia gli asset e imposta esplicitamente il JPG verificato per il desktop.
if [[ -d "$SCRIPT_DIR/wallpaper" ]]; then
    install -d -m 0755 "$USER_HOME/.wallpaper"
    cp -a "$SCRIPT_DIR/wallpaper/." "$USER_HOME/.wallpaper/"
    if [[ -f "$SCRIPT_DIR/wallpaper/wallpaper.jpg" ]]; then
        install -m 0644 -o "$ACTUAL_USER" -g "$(id -gn "$ACTUAL_USER")" \
            "$SCRIPT_DIR/wallpaper/wallpaper.jpg" "$USER_HOME/.wallpaper/wallpaper.jpg"
    else
        warn "Desktop wallpaper missing: $SCRIPT_DIR/wallpaper/wallpaper.jpg"
    fi
else
    warn "Missing source: $SCRIPT_DIR/wallpaper"
fi

copy_if_exists "$SCRIPT_DIR/config/terminator/config"    "$USER_HOME/.config/terminator/config"

copy_if_exists "$SCRIPT_DIR/config/i3/config"            "$USER_HOME/.config/i3/config"
copy_if_exists "$SCRIPT_DIR/config/i3/i3blocks.conf"     "$USER_HOME/.config/i3/i3blocks.conf"
copy_if_exists "$SCRIPT_DIR/config/i3/clipboard_fix.sh"  "$USER_HOME/.config/i3/clipboard_fix.sh"
copy_if_exists "$SCRIPT_DIR/config/i3/set-resolution-vmware.sh" "$USER_HOME/.config/i3/set-resolution-vmware.sh"
copy_if_exists "$SCRIPT_DIR/config/compton/compton.conf" "$USER_HOME/.config/compton/compton.conf"
copy_if_exists "$SCRIPT_DIR/config/rofi/config"          "$USER_HOME/.config/rofi/config"

# null0x application launcher (transparent background, neon fuchsia border/selection, white selected title)
LAUNCHER_SOURCE="$SCRIPT_DIR/config/rofi/themes/null0x-launcher.rasi"
LAUNCHER_DEST="$USER_HOME/.config/rofi/themes/null0x-launcher.rasi"
if [[ -f "$LAUNCHER_SOURCE" ]]; then
    mkdir -p "$USER_HOME/.config/rofi/themes"
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$LAUNCHER_SOURCE" "$LAUNCHER_DEST"
else
    warn "Rofi launcher theme missing; skipping launcher theme installation."
fi

# null0x Rofi Type-5 powermenu (icon-only, black / acid-green)
POWERMENU_SOURCE="$SCRIPT_DIR/config/rofi/powermenu/type-5"
POWERMENU_DEST="$USER_HOME/.config/rofi/powermenu/type-5"

if [[ -f "$POWERMENU_SOURCE/powermenu.sh" && -f "$POWERMENU_SOURCE/style-1.rasi" ]]; then
    mkdir -p "$POWERMENU_DEST"
    install -m 0755 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$POWERMENU_SOURCE/powermenu.sh" "$POWERMENU_DEST/powermenu.sh"
    install -m 0644 -o "$ACTUAL_USER" -g "$ACTUAL_USER" \
        "$POWERMENU_SOURCE/style-1.rasi" "$POWERMENU_DEST/style-1.rasi"
else
    warn "Rofi powermenu source files are missing; skipping powermenu installation."
fi

if [[ -d "$SCRIPT_DIR/config/polybar" ]]; then
    cp -a "$SCRIPT_DIR/config/polybar/." "$USER_HOME/.config/polybar/"
fi

# Flameshot: use X11 legacy capture to avoid Screenshot Portal timeouts
if [[ -f "$SCRIPT_DIR/config/flameshot/flameshot.ini" ]]; then
    install -D -m 0644 -o "$ACTUAL_USER" -g "$(id -gn "$ACTUAL_USER")" \
        "$SCRIPT_DIR/config/flameshot/flameshot.ini" \
        "$USER_HOME/.config/flameshot/flameshot.ini"
else
    warn "Flameshot configuration missing; keeping the existing user configuration."
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
    "$USER_HOME/.config/i3/set-resolution-vmware.sh" \
    "$USER_HOME/.config/i3/clipboard_fix.sh" \
    "$USER_HOME/.config/i3/scripts/kitty-3pane.sh" \
    "$USER_HOME/.config/rofi/powermenu/type-5/powermenu.sh" \
    "$USER_HOME/.fehbg"
do
    if [[ -f "$f" ]]; then chmod +x "$f"; fi
done

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
  1. Al login verifica che sia selezionata la sessione i3 (configurata come predefinita).
  2. Apri una nuova shell zsh; se sei già in una shell aperta, esegui: source ~/.zshrc
     Verifica pywal con: command -v wal
  3. Fastfetch: configurazione e logo 0x0PS installati.
     Avvialo manualmente con: fastfetch
  4. CLI neon: prova git st, git lg, bat <file>, fzf e btop.
     Se il comando bat non esiste, l'installer configura l'alias verso batcat.
  4. Valida il config i3:  i3 -C -c ~/.config/i3/config
  5. Nel config i3 sostituisci i riferimenti al vecchio terminale:
       grep -nE 'alacritty|terminator' ~/.config/i3/config
     con "kitty".
  6. tmux: apri tmux e premi prefix + I per installare i plugin TPM.
  7. lxappearance per il tema GTK se serve.

Backup del .zshrc precedente: ~/.zshrc.bak
============================================================
EOF
