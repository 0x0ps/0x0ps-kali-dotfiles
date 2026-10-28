#!/usr/bin/env bash

## Original author : Aditya Shakya (adi1090x)
## null0x customization : black / acid-green icon-only power menu
## Github : @adi1090x
#
## Rofi   : Power Menu
#
## Available Styles
#
## style-1   style-2   style-3   style-4   style-5

# Current Theme
dir="$HOME/.config/rofi/powermenu/type-5"
theme='style-1'

# CMDs
lastlogin="$(last "$USER" | head -n1 | tr -s ' ' | cut -d' ' -f5,6,7)"
uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

# Options — use classic Font Awesome glyphs supported by Nerd Font builds
hibernate=''
shutdown=''
reboot=''
lock=''
suspend=''
logout=''
yes=''
no=''

# Rofi CMD
rofi_cmd() {
	rofi -dmenu \
		-format i \
		-p " $USER@$host" \
		-mesg " Last Login: $lastlogin  |   Uptime: $uptime" \
		-theme "${dir}/${theme}.rasi"
}

# Confirmation CMD
confirm_cmd() {
	rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 350px;}' \
		-theme-str 'mainbox {children: [ "message", "listview" ];}' \
		-theme-str 'listview {columns: 2; lines: 1;}' \
		-theme-str 'element-text {horizontal-align: 0.5;}' \
		-theme-str 'textbox {horizontal-align: 0.5;}' \
		-dmenu \
		-format i \
		-p 'Confirmation' \
		-mesg 'Are you Sure?' \
		-theme "${dir}/${theme}.rasi"
}

# Ask for confirmation
confirm_exit() {
	printf '%s\n%s\n' "$yes" "$no" | confirm_cmd
}

# Pass variables to Rofi dmenu
run_rofi() {
	printf '%s\n' "$lock" "$suspend" "$logout" "$hibernate" "$reboot" "$shutdown" | rofi_cmd
}

# Execute Command
run_cmd() {
	selected="$(confirm_exit)"
	if [[ "$selected" == "0" ]]; then
		if [[ $1 == '--shutdown' ]]; then
			systemctl poweroff
		elif [[ $1 == '--reboot' ]]; then
			systemctl reboot
		elif [[ $1 == '--hibernate' ]]; then
			systemctl hibernate
		elif [[ $1 == '--suspend' ]]; then
			mpc -q pause
			amixer set Master mute
			systemctl suspend
		elif [[ $1 == '--logout' ]]; then
			if [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
				openbox --exit
			elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
				bspc quit
			elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
				i3-msg exit
			elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
				qdbus org.kde.ksmserver /KSMServer logout 0 0 0
			fi
		fi
	else
		exit 0
	fi
}

# Actions — use the selected row index, not the icon glyph returned by Rofi
chosen="$(run_rofi)"
case "$chosen" in
	0)
		if [[ -x '/usr/bin/betterlockscreen' ]]; then
			betterlockscreen -l
		elif [[ -x '/usr/bin/i3lock' ]]; then
			i3lock
		fi
		;;
	1)
		run_cmd --suspend
		;;
	2)
		run_cmd --logout
		;;
	3)
		run_cmd --hibernate
		;;
	4)
		run_cmd --reboot
		;;
	5)
		run_cmd --shutdown
		;;
esac
