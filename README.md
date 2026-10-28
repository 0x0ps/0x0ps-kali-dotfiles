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
- **Kitty** terminal configuration with the 0x0ps dark / neon palette.
- **Neon CLI toolkit:** `lsd`, `bat`, `fzf`, `htop`, and Git color settings / aliases.
- **tmux** configuration and TPM plugin manager.
- **SPICE clipboard integration** for compatible virtual machines.
- **Adaptive SPICE display resolution** for virtual displays exposed by QXL/SPICE.
- Wallpaper setup using `feh`.
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
- Open a new Zsh session to load the updated shell configuration and fzf key bindings.
- CLI tools use the 0x0ps palette: `lsd` for listings, `bat` for syntax-highlighted files, `fzf` for fuzzy search, `htop` for process monitoring, and Git aliases `git st` / `git lg`.
- The installer copies the managed `lsd`, `bat`, `fzf`, and `htop` configs into `~/.config`. Review local changes before rerunning the installer.

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
| `Mod + Shift + v` | Show CopyQ clipboard history |
| `Mod + Shift + Enter` | Run the Kitty three-pane script |

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

> **Tip:** `Mod + Esc` opens the Rofi power menu. Power off, reboot, suspend, hibernate, and logout require a second confirmation. Press `Esc` to close the menu without taking action. Shortcuts can differ if you edit your local i3 configuration.

## Adaptive SPICE resolution

The repository includes `config/i3/set-resolution.sh`. During installation it is copied to:

```text
~/.config/i3/set-resolution.sh
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

Inspect display modes:

```bash
xrandr
```

Check SPICE guest-agent packages and services:

```bash
dpkg -l | grep spice-vdagent
pgrep -af spice-vdagent
```

## Custom scripts

Installed helper scripts are placed in `~/.config/bin/` when provided by the repository. Examples include:

- `htb.sh` — HTB VPN status.
- `eth.sh` — Ethernet status.
- `usb.sh` — USB network status.
- `htb_target.sh` — current target display.
- `target` — text file used to store the current target.

The exact modules available depend on the files in the repository version you install.

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
ls -l ~/.wallpaper/wallpaper.png
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
