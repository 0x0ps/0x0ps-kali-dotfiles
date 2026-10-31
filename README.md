# 0x0ps Kali Linux Dotfiles

A customized Kali Linux desktop setup built around **i3**, Polybar, Kitty, Rofi, tmux, and practical helper scripts. It also includes SPICE clipboard support and an adaptive display-resolution script for Kali VMs running under Proxmox with SPICE/QXL graphics.

> **Important:** This repository configures a desktop environment, not just a wallpaper or a single script. The installer installs packages and copies configuration files into your home directory. Read the instructions and review the installer before running it on an existing system.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [First login](#first-login)
- [i3 keyboard shortcuts](#i3-keyboard-shortcuts)
- [Adaptive SPICE resolution](#adaptive-spice-resolution)
- [Useful commands](#useful-commands)
- [Troubleshooting](#troubleshooting)
- [Updating](#updating)
- [Uninstalling or reverting changes](#uninstalling-or-reverting-changes)

## Features

- **i3 window manager** configuration and keyboard shortcuts.
- **Polybar** with custom status modules, including HTB VPN, USB/Ethernet, and target information.
- **Rofi** application launcher with a custom translucent black theme and acid-green accents (`#A6FF00`).
- **Rofi Type-5 powermenu** with icon-only controls, black background, and acid-green accents (`#A6FF00`).
- **Kitty** terminal configuration with the 0x0ps dark / neon palette.\n- **Fastfetch** with a custom 0x0PS PNG logo, Kitty image rendering, and the fuchsia / cyan / white module palette; it launches automatically in each new interactive Zsh terminal.
- **Neon CLI toolkit:** `lsd` with acid-green directories (`#A6FF00`), white files, fuchsia executables, and cyan symlinks; plus `bat`, `fzf`, `btop`, and Git color settings / aliases.
- **tmux** configuration and TPM plugin manager.
- **SPICE clipboard integration** for compatible virtual machines.
- **Adaptive SPICE display resolution** for virtual displays exposed by QXL/SPICE.
- Wallpaper setup using `feh`.
- **Matching login-screen wallpaper** for LightDM / Slick Greeter, installed from `wallpaper/wallpaper.jpg`.
- **Custom 0x0PS Slick Greeter theme** with white text, acid-green focus accents (`#A6FF00`), and neon-fuchsia borders (`#FF00AF`).
- Utility scripts for network status and target tracking.
- Optional pywal support.

## Requirements

- A supported **Kali Linux** installation. The installer is designed for Kali Linux 2026.x; other releases may need adjustments.
- A graphical desktop session using **X11 and i3**. This setup is not intended for Wayland sessions.
- An internet connection to download packages, fonts, themes, and tools.
- A normal user account with `sudo` access.
- For adaptive display resizing: a Proxmox (or compatible) VM using **SPICE**, a supported virtual graphics adapter such as **QXL**, and the SPICE guest agent installed and working.

The adaptive-resolution script is optional outside SPICE/QXL environments. It looks for a connected output named `Virtual-*`, which is typical for QXL/SPICE but may not match every virtual or physical display setup.

## Installation

### 1. Download the repository

Open a terminal in Kali and run:

```bash
sudo apt update
sudo apt install -y git
git clone https://github.com/0x0ps/0x0ps-kali-dotfiles.git
cd 0x0ps-kali-dotfiles
```

### 2. Review the installer

The installer installs packages and copies this repository's configuration into your home directory. Review it before running:

```bash
less install.sh
```

Back up any personal configuration you want to keep, especially files under `~/.config/i3`, `~/.config/polybar`, `~/.config/kitty`, `~/.config/rofi`, `~/.zshrc`, and `~/.tmux.conf`.

### 3. Run the installer

```bash
chmod +x install.sh
sudo ./install.sh
```

Use `sudo` as shown so the installer can install system packages. The script attempts to identify the normal desktop user and install user configuration into that account's home directory. Run it from the cloned repository directory.

### Login-screen wallpaper

The installer also configures LightDM with **Slick Greeter** and installs the repository image
`wallpaper/wallpaper.jpg` as:

```text
/usr/share/backgrounds/0x0ps-login-wallpaper.jpg
```

The same image is used as the Slick Greeter background. It is copied to a system-readable
location because the greeter cannot read files inside a user home directory with private
(`0700`) permissions. The installer updates the Slick Greeter settings and keeps a timestamped
backup of an existing `/etc/lightdm/slick-greeter.conf`.

The installer also creates an independent GTK theme named `0x0PS-Greeter` by copying Kali-Dark
and applying the repository stylesheet at `config/lightdm/0x0ps.css`. The original Kali-Dark
theme is left untouched. Slick Greeter uses the custom theme for its login controls; the
wallpaper remains unchanged.

To change the login wallpaper, replace `wallpaper/wallpaper.jpg` in the repository with your
own image (keeping that filename), then review and rerun the installer. Back up local changes
before rerunning it.

### 4. Reboot and choose i3

When the installer finishes:

1. Reboot or log out of the current desktop session.
2. At the login screen, select **i3** as the session, if it is not already selected.
3. Log in and allow the desktop components to start.

If you are using a display manager that does not offer an i3 session, check that the `i3` package is installed and select or configure the X11 i3 session manually.

### 5. Rofi power menu

The installer places the customized menu in `~/.config/rofi/powermenu/type-5/` and binds **Win/Super + Esc** to it. The menu uses the black / acid-green theme and icon-only actions. Press `Esc` to close it; selecting a power action opens a confirmation prompt.

### Rofi application launcher

The installer places the custom launcher theme at `~/.config/rofi/themes/null0x-launcher.rasi`.
Press **Win/Super + D** to browse installed applications with a translucent dark background,
acid-green labels, and an acid-green selection highlight.

### 6. Complete optional setup

- Open a terminal and start tmux. Use `Ctrl+b`, then `Shift+i` to install tmux plugins through TPM.
- Run `lxappearance` to select a GTK theme such as **Arc-Dark**, if desired.
- The installer copies the repository wallpaper into `~/.wallpaper` and configures `feh` to use it.
- Open a new Zsh session to load the updated shell configuration and fzf key bindings. Fastfetch runs automatically in each new interactive Zsh terminal and displays the repository's `assets/fastfetch/0x0ps.png` logo.
- CLI tools use the 0x0ps palette: `lsd` for listings (acid-green directories `#A6FF00`, white files, fuchsia executables, cyan symlinks), `bat` for syntax-highlighted files, `fzf` for fuzzy search, `btop` for process monitoring, and Git aliases `git st` / `git lg`.
- The installer copies the managed `fastfetch`, `lsd`, `bat`, `fzf`, and `btop` configs into `~/.config`. Review local changes before rerunning the installer.

## i3 keyboard shortcuts

These shortcuts reflect the key bindings in this repository's current `config/i3/config`.

**Key notation:** `Mod` is the **Super/Windows key** on most keyboards. Hold the listed keys together unless the action says otherwise.

### Windows and applications

| Shortcut | Action |
|---|---|
| `Mod + Enter` | Open Kitty terminal |
| `Mod + d` | Open the themed Rofi application launcher |
| `Mod + Shift + f` | Open Firefox |
| `Mod + w` | Close the focused window |
| `Mod + f` | Toggle fullscreen |
| `Mod + Shift + Space` | Toggle floating mode for the focused window |
| `Mod + Space` | Switch focus between tiled and floating windows |
| `Mod + a` | Focus the parent container |
| `Print` | Open Flameshot for a screenshot |
| `Mod + Shift + Enter` | Run the Kitty three-pane script |
| `Alt + Shift + H` | Create a side-by-side split inside Kitty |
| `Alt + Shift + V` | Create a top/bottom split inside Kitty |
| `Alt + Shift + W` | Close the active Kitty split/window |
| `Ctrl + ← / → / ↑ / ↓` (in Kitty) | Move focus between Kitty splits |
| `Ctrl + Shift + F5` (in Kitty) | Reload Kitty configuration |

### Move focus and windows

| Shortcut | Action |
|---|---|
| `Mod + ← / ↓ / ↑ / →` | Move focus to the window in that direction |
| `Mod + j / k / l / ;` | Move focus left / down / up / right |
| `Mod + Shift + ← / ↓ / ↑ / →` | Move the focused window in that direction |
| `Mod + Shift + j / k / l / ;` | Move the focused window left / down / up / right |

### Workspaces

| Shortcut | Action |
|---|---|
| `Mod + 1` … `Mod + 9` | Switch to workspace 1–9 |
| `Mod + 0` | Switch to workspace 10 |
| `Mod + Shift + 1` … `Mod + Shift + 9` | Move the focused window to workspace 1–9 |
| `Mod + Shift + 0` | Move the focused window to workspace 10 |

### Layout and window arrangement

| Shortcut | Action |
|---|---|
| `Mod + h` | Split horizontally |
| `Mod + v` | Split vertically |
| `Mod + s` | Use stacking layout |
| `Mod + Shift + t` | Use tabbed layout |
| `Mod + e` | Toggle split layout |
| `Mod + r` | Enter resize mode |
| `Enter` or `Esc` (in resize mode) | Leave resize mode |

While in resize mode:

| Shortcut | Action |
|---|---|
| `← / →` | Shrink / grow width |
| `↑ / ↓` | Shrink / grow height |
| `j / ;` | Shrink / grow width |
| `k / l` | Grow / shrink height |

### i3 controls and session

| Shortcut | Action |
|---|---|
| `Mod + Shift + c` | Reload the i3 configuration |
| `Mod + Shift + r` | Restart i3 |
| `Mod + Shift + e` | Show the i3 exit confirmation |
| `Mod + Esc` | Open the Rofi power menu (choose an action, then confirm) |

> **Kitty split note:** Kitty's `Alt + Shift + H` and `Alt + Shift + V` create internal splits; these are separate from i3's `Mod + h` / `Mod + v` window splits. The CopyQ `Mod + Shift + v` binding is intentionally disabled to avoid intercepting the Kitty shortcut on Alt-based Mod configurations.

> **Tip:** `Mod + Esc` opens the Rofi power menu. Power off, reboot, suspend, hibernate, and logout require a second confirmation. Press `Esc` to close the menu without taking action. Shortcuts can differ if you edit your local i3 configuration.

## Adaptive SPICE resolution

The repository includes `config/i3/set-resolution-vmware.sh`. During installation it is copied to:

```text
~/.config/i3/set-resolution-vmware.sh
```

The i3 configuration starts it automatically. The script periodically checks the connected virtual display and its preferred `xrandr` mode. When SPICE advertises a stable new preferred mode, the script applies it and restores the wallpaper. This helps the Kali desktop follow Remote Viewer window resizing and maximization without hard-coding a resolution such as `3840x985`.

### Enablement checklist

For this feature to work, check that:

1. The VM is opened through **Remote Viewer / SPICE**.
2. The VM's virtual graphics configuration supports the SPICE display integration (for example, QXL).
3. The SPICE guest agent is installed and running in Kali.
4. The session is X11 with i3, and `xrandr` lists a connected output such as `Virtual-1`.
5. The i3 config contains the startup entry:
   ```i3
   exec --no-startup-id ~/.config/i3/set-resolution.sh
   ```

Check the display and the script with:

```bash
xrandr
pgrep -af '[s]et-resolution.sh'
```

The script is designed for common QXL/SPICE output names, but display behavior can differ across hypervisors, graphics adapters, Remote Viewer versions, and desktop environments. If your output is not named `Virtual-*`, or the preferred mode does not track the Remote Viewer window, the script may need adaptation for your setup.

### Disable adaptive resizing

To stop the script for the current session, find its process and stop it:

```bash
pkill -f '[s]et-resolution.sh'
```

To prevent it from starting again, edit `~/.config/i3/config` and comment out or remove this line:

```i3
exec --no-startup-id ~/.config/i3/set-resolution.sh
```

Then reload i3 with `Mod+Shift+c`, or log out and back in.

## Useful commands

Validate the i3 configuration:

```bash
i3 -C -c ~/.config/i3/config
```

Reload i3:

```bash
i3-msg reload
```

Validate the i3 configuration before reloading:

```bash
i3 -C -c ~/.config/i3/config
```

Reload Kitty configuration from inside Kitty with `Ctrl+Shift+F5`.

Inspect the relevant i3 bindings:

```bash
grep -nE 'copyq show|split v' ~/.config/i3/config
```

Inspect display modes:

```bash
xrandr
```

Check SPICE guest-agent packages and services:

```bash
dpkg -l | grep spice-vdagent
pgrep -af spice-vdagent
```

## Custom scripts and automation

The shell scripts below are version-controlled in this repository. **They are not separate mystery downloads**: clone or pull this repository, then the main installer copies the supported scripts into your home directory and sets executable permissions. Most scripts are started by i3 or Polybar automatically; a few are optional utilities.

### Scripts installed automatically

| Repository path | Installed path / trigger | What it does |
|---|---|---|
| `config/i3/scripts/power-performance.sh` | `~/.config/i3/scripts/power-performance.sh`; started at i3 login | Disables X11 screen blanking and DPMS, then requests the **Performance** power profile through `powerprofilesctl`. |
| `config/i3/set-resolution-vmware.sh` | `~/.config/i3/set-resolution-vmware.sh`; started at i3 login | Watches VMware `Virtual-*` display modes; applies a newly advertised preferred resolution, reapplies the wallpaper, and restarts Polybar. Log: `/tmp/0x0ps-vmware-resize.log`. |
| `config/i3/clipboard_fix.sh` | `~/.config/i3/clipboard_fix.sh`; started by i3 | Restarts the VMware user agent process (`vmtoolsd -n vmusr`) to support clipboard integration. |
| `config/polybar/launch.sh` | `~/.config/polybar/launch.sh`; started by i3 | Quits existing Polybar instances and launches the configured bar. Logs: `/tmp/polybar1.log` and `/tmp/polybar2.log`. |
| `config/polybar/scripts/workspaces.sh` | Used by the Polybar workspace module | Displays i3 workspaces 1–10 and highlights the active workspace. |
| `config/bin/htb.sh` | `~/.config/bin/htb.sh`; called by Polybar | Shows the `tun0` address when the HTB VPN is connected, otherwise “Disconnected”. |
| `config/bin/eth.sh` | `~/.config/bin/eth.sh`; called by Polybar | Shows the `eth0` address or disconnected status. |
| `config/bin/usb.sh` | `~/.config/bin/usb.sh`; called by Polybar | Shows the `usb0` address or disconnected status. |
| `config/bin/htb_target.sh` | `~/.config/bin/htb_target.sh`; called by Polybar | Reads the current target from `~/.config/bin/target` and displays its IP/name. |
| `config/i3/scripts/kitty-3pane.sh` | `~/.config/i3/scripts/kitty-3pane.sh`; `Mod + Shift + Enter` | Opens three Kitty terminals in the predefined i3 layout on workspace 9. It does nothing if workspace 9 is already focused. |
| `config/i3/scripts/kitty-resize-mode.sh` | `~/.config/i3/scripts/kitty-resize-mode.sh`; `Mod + Ctrl + r` | Floats the focused Kitty window and enters the dedicated Kitty resize mode. Focus Kitty first; use the resize-mode keys configured in i3, then press Enter or Esc to leave the mode. |
| `config/rofi/powermenu/type-5/powermenu.sh` | `~/.config/rofi/powermenu/type-5/powermenu.sh`; `Mod + Esc` | Opens the themed power menu for lock, suspend, logout, hibernate, reboot, and shutdown. Power actions require confirmation. System sleep targets are masked by the main installer, so suspend/hibernate are intentionally unavailable unless you later unmask them. |

The main installer also creates the target file at `~/.config/bin/target`. In a new Zsh shell, set or clear the target with:

```bash
target 10.10.11.42
cleartarget
```

The `target` helper currently stores the IP supplied as its first argument. The Polybar target module reads that file.

### Optional scripts in the repository

These are not run by the main desktop installer:

| Script | Purpose | How to run |
|---|---|---|
| `install-bloodhound.sh` | Installs Docker, the official BloodHound CLI, and BloodHound Community Edition; updates an existing installation when its config is present. Supports amd64 and arm64. | From the cloned repository: `sudo ./install-bloodhound.sh`. Save the generated admin password. A new login may be needed after Docker group membership is added. |
| `fix-terminal.sh` | Restores the GNOME Terminal dconf settings from `config/gnome_terminal_settings_backup.txt`. | From the repository root, run `dconf load /org/gnome/terminal/ < ./config/gnome_terminal_settings_backup.txt`. The helper itself is simply a wrapper for that command. |

### Install or refresh the scripts manually

Normally, use the main installer described above. If you only want to copy/update the helper scripts without rerunning the full installer, run these commands from the repository root:

```bash
mkdir -p ~/.config/i3/scripts ~/.config/i3 ~/.config/bin ~/.config/polybar/scripts ~/.config/rofi/powermenu/type-5
install -Dm755 config/i3/scripts/power-performance.sh ~/.config/i3/scripts/power-performance.sh
install -Dm755 config/i3/scripts/kitty-3pane.sh ~/.config/i3/scripts/kitty-3pane.sh
install -Dm755 config/i3/scripts/kitty-resize-mode.sh ~/.config/i3/scripts/kitty-resize-mode.sh
install -Dm755 config/i3/set-resolution-vmware.sh ~/.config/i3/set-resolution-vmware.sh
install -Dm755 config/i3/clipboard_fix.sh ~/.config/i3/clipboard_fix.sh
install -Dm755 config/polybar/launch.sh ~/.config/polybar/launch.sh
install -Dm755 config/polybar/scripts/workspaces.sh ~/.config/polybar/scripts/workspaces.sh
install -Dm755 config/bin/htb.sh ~/.config/bin/htb.sh
install -Dm755 config/bin/eth.sh ~/.config/bin/eth.sh
install -Dm755 config/bin/usb.sh ~/.config/bin/usb.sh
install -Dm755 config/bin/htb_target.sh ~/.config/bin/htb_target.sh
install -Dm755 config/rofi/powermenu/type-5/powermenu.sh ~/.config/rofi/powermenu/type-5/powermenu.sh
touch ~/.config/bin/target
```

Then validate and reload i3:

```bash
i3 -C -c ~/.config/i3/config
i3-msg reload
```

The manual copy command does not install dependencies or apply system-wide sleep settings. For the complete setup, run `sudo ./install.sh` after reviewing it.

## Externally downloaded components

The main installer downloads or installs these components in addition to files stored in this repository:

- **APT packages:** i3, Polybar, Kitty, Conky, Rofi, Picom, SPICE agent, `power-profiles-daemon`, and the other dependencies listed in `install.sh`.
- **uv:** bootstrapped using Astral's official install script; then used to install `pywal`.
- **Nerd Fonts:** Iosevka, RobotoMono, and Hack ZIP archives from the Nerd Fonts GitHub releases.
- **VictorConky upstream assets:** the installer clones `Gictorbit/victorconky` to obtain its font files. The 0x0ps Conky artwork and Conky configuration are taken from this repository.
- **TPM:** cloned from `tmux-plugins/tpm` into `~/.tmux/plugins/tpm`.
- **Firefox theme:** the installer queries Mozilla Add-ons for the Cyberpunk Neon Rain theme ID and configures Firefox enterprise policy to install it on Firefox startup.

The installer also applies system-level power settings: it masks `sleep.target`, `suspend.target`, `hibernate.target`, and `hybrid-sleep.target`; disables optional screen-locker / desktop power-manager services when present; and enables `power-profiles-daemon`. At i3 login, `power-performance.sh` disables X11 screensaver/DPMS and requests the Performance profile. A VM or host may not expose a Performance profile; in that case, the helper reports that it is unavailable while the no-blanking settings still apply.

**Security note:** review the installer and downloaded upstream code before execution. The uv bootstrap is piped directly to a shell by the installer, and upstream repositories/releases may change over time.

## Troubleshooting

### The desktop does not switch to i3

Log out and select the i3 session at the login screen. Confirm the package is installed:

```bash
dpkg -l i3-wm
```

### SPICE resizing does not work

Run:

```bash
xrandr
pgrep -af '[s]et-resolution.sh'
```

Confirm that a connected `Virtual-*` output appears and that the script is running. Check that the preferred mode (`+` in `xrandr` output) changes when you resize Remote Viewer. Also verify that SPICE guest tools are installed and the VM is using a compatible display device.

### The wallpaper is missing

Check that the image exists:

```bash
ls -l /usr/share/backgrounds/0x0ps-login-wallpaper.jpg
ls -l ~/.wallpaper/wallpaper.jpg
```

If you use a different image, update `~/.fehbg` or the wallpaper path used by your configuration.

### A configuration or installation step fails

Read the error printed by the installer and verify network connectivity and package availability. Since the installer changes system packages and user configuration, do not repeatedly rerun it without checking the failure and reviewing any existing backups.

## Updating

To download the latest repository changes:

```bash
cd 0x0ps-kali-dotfiles
git pull --ff-only
```

Then review the changes before running the installer again. Re-running `sudo ./install.sh` can overwrite configuration files copied from the repository. Back up local customizations first.

If you only want to update the adaptive-resolution script, review the latest version at:

[config/i3/set-resolution.sh](https://github.com/0x0ps/0x0ps-kali-dotfiles/blob/main/config/i3/set-resolution.sh)

Do not replace configuration files blindly if you have made local edits.

## Uninstalling or reverting changes

This repository does not currently provide a fully automatic uninstaller. Restore your own backups for any configuration files that were replaced, and manually remove packages or settings only if you are sure they are no longer needed. To disable just the adaptive-resolution feature, follow [Disable adaptive resizing](#disable-adaptive-resizing).

## Disclaimer

This is a community desktop configuration project intended for personal use, learning, and lab environments. Review scripts before executing them, keep backups, and test changes in a VM before applying them to a system you depend on.

---

**Repository:** [github.com/0x0ps/0x0ps-kali-dotfiles](https://github.com/0x0ps/0x0ps-kali-dotfiles)
