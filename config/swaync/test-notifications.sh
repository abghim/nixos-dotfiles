#!/usr/bin/env bash
set -euo pipefail

# Usage: ./test-notifications.sh [--step | --dry-run | --fetch-only]
# DELAY=2 controls pacing. Images persist in XDG_CACHE_HOME for notification history.
dry_run=0 step=0 fetch_only=0
for arg in "$@"; do
	case "$arg" in
		--step) step=1 ;;
		--dry-run) dry_run=1 ;;
		--fetch-only) fetch_only=1 ;;
		-h|--help)
			printf '%s\n' \
				'Usage: test-notifications.sh [--step] [--dry-run] [--fetch-only]' \
				'  --step        Press Enter between examples instead of waiting.' \
				'  --dry-run     Print commands without downloading or sending anything.' \
				'  --fetch-only  Download sample images, then exit.' \
				'Environment: DELAY=1.5, XDG_CACHE_HOME=~/.cache' \
				'Actions print their identifiers to this terminal; listeners expire after 3 minutes.' \
				'Inline replies are visual tests: notify-send cannot receive reply text.' \
				'No notifications are cleared, and DND is left unchanged.'
			exit 0 ;;
		*) printf 'Unknown option: %s\n' "$arg" >&2; exit 2 ;;
	esac
done

cache="${XDG_CACHE_HOME:-$HOME/.cache}/swaync-showcase"
avatar="$cache/avatar.jpg"
landscape="$cache/landscape.jpg"
portrait="$cache/portrait.jpg"
base=(--app-name='SwayNC Showcase' --hint=boolean:SWAYNC_NO_SCRIPT:true)

if (( ! dry_run )); then
	for command in curl notify-send timeout; do
		command -v "$command" >/dev/null || { printf 'Missing dependency: %s\n' "$command" >&2; exit 1; }
	done
	mkdir -p "$cache"
	# Fixed Picsum photo IDs, with square, landscape, and portrait crops.
	for spec in 'avatar:1025:192:192' 'landscape:1018:960:540' 'portrait:1025:360:640'; do
		IFS=: read -r name photo width height <<< "$spec"
		if [[ ! -s "$cache/$name.jpg" ]]; then
			printf 'Downloading %s...\n' "$name"
			curl --fail --location --silent --show-error --retry 2 \
				--connect-timeout 10 --max-time 45 \
				--output "$cache/$name.jpg.part" "https://picsum.photos/id/$photo/$width/$height"
			mv "$cache/$name.jpg.part" "$cache/$name.jpg"
		fi
	done
	printf 'Sample images: %s\n' "$cache"
fi
(( ! fetch_only )) || exit 0

send() {
	local interactive=0 arg
	for arg in "$@"; do
		[[ "$arg" != --action=* ]] || interactive=1
	done
	if (( dry_run )); then
		printf '%q ' notify-send "${base[@]}" "$@" >&2
		printf '\n' >&2
	elif (( interactive )); then
		# --action implies --wait; a bounded background listener keeps the suite moving.
		timeout 180s notify-send "${base[@]}" "$@" &
	else
		notify-send "${base[@]}" "$@"
	fi
	if (( ! dry_run )); then
		if (( step )); then
			read -r -p 'Enter for next example... ' _
		else
			sleep "${DELAY:-1.5}"
		fi
	fi
}

printf '%s\n' 'Open the notification center to inspect history and grouped notifications.' \
	'Turn DND off for popups. Critical examples need manual dismissal.'

# The four combinations of .image and .body-image.
send '01 | No images' 'Short body. Check the left, right, top, and bottom padding.'
send --icon="$avatar" '02 | Primary image only' 'Square photo as the primary image; no body image.'
send '03 | Body image only' "No primary icon; a wide photo below the text.<img src=\"$landscape\"/>"
send --icon="$avatar" '04 | Both images' "Primary icon plus a wide body image.<img src=\"$landscape\"/>"
send '05 | Title only, no icon'
send --icon=dialog-information-symbolic '06 | Title only, theme icon'
send --icon=dialog-information-symbolic '07 | Named theme icon' 'An icon-theme image rather than a photo.'
send --app-icon=dialog-information-symbolic --hint="string:image-path:$avatar" \
	'08 | Image with application badge' 'The photo is .image; the smaller overlay is .app-icon.'
send '09 | Body image without text' "<img src=\"$landscape\"/>"
send --icon="$avatar" '10 | Portrait body image' "A tall image should scale down without breaking the layout.<img src=\"$portrait\"/>"

long_body='A longer notification body to check wrapping, spacing, and clipping. This resembles a detailed email preview or a chat message containing several sentences. Neither the presence nor absence of an icon should change the outer content padding. Open the notification center to compare its expanded text with the shorter floating popup.'
send '11 | Long body without an icon' "$long_body"
send --icon="$avatar" '12 | Long body with an icon' "$long_body"
send '13 | A deliberately very long notification title that should ellipsize cleanly without colliding with the timestamp or close button' 'Short body.'
send '14 | Multiple paragraphs' $'First line.\nSecond line.\n\nA separate paragraph.\nAnother line to check vertical rhythm.\nFive lines of content.\nSix lines.\nSeven lines.\nEight lines.\nNine lines.\nTen lines.\nEleven lines: compare popup truncation with the center.'
send '15 | Markup and escaping' '<b>Bold</b>, <i>italic</i>, <u>underline</u>, and &lt;escaped text&gt; &amp; symbols.'
send '16 | Long unbroken text' 'https://example.com/downloads/verylongsegmentwithoutanyspaces0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/archive.tar.zst'

send --urgency=low --icon=dialog-information-symbolic '17 | Low urgency' 'Background task finished. Uses the low-priority timeout.'
send --urgency=normal '18 | Normal urgency' 'A regular notification using the configured default timeout.'
send --urgency=critical --icon=dialog-warning-symbolic '19 | Critical urgency' 'Persistent warning with the critical border. Dismiss manually.'
send --expire-time=1500 '20 | Short custom timeout' 'The popup should disappear after about 1.5 seconds; check history.'
send --transient --expire-time=3000 '21 | Transient notification' 'Popup only: this should not remain in notification-center history.'

send --icon=dialog-question-symbolic --action=open='Open' --action=snooze='Remind me later' --action=dismiss='Dismiss' \
	'22 | Three action buttons' 'Click a button; its identifier prints in the terminal. No real commands are executed.'
send --action=default='Open notification' --action=archive='Archive' \
	'23 | Default click action' 'Click the notification body for "default", or the Archive button for "archive".'
send --action=one='A longer first action label' --action=two='Another long action label' --action=three='Third action' --action=four='Fourth action' \
	'24 | Action wrapping, no icon' 'Check button padding and wrapping when labels compete for space.'
send --hint=boolean:resident:true --action=default='Activate' --action=retry='Retry' \
	'25 | Resident action' 'Invoking an action should leave this notification present. Close it manually afterward.'
send --icon="$avatar" --action=inline-reply='Send' --action=default='Open conversation' \
	--hint=string:x-kde-reply-placeholder-text:'Write a test reply...' \
	'26 | Inline reply' 'A chat-style reply field. Sending dismisses it; notify-send does not receive the reply text.'
send --icon=dialog-password-symbolic '27 | Automatic 2FA action' 'Your verification code is 482951. Never share this code. SwayNC should add a COPY button.'

for value in 0 25 65 100; do
	send --icon=folder-download-symbolic --hint=string:x-canonical-private-synchronous:swaync-showcase-download \
		--hint="int:value:$value" '28 | Updating download progress' "Download is $value% complete. Each update should replace the same notification."
done
send --hint=int:value:45 '29 | Progress without an icon' 'A standalone progress bar at 45%.'

# Capture the ID for explicit replacement, independently of synchronous-tag updates.
id=$(send --print-id '30 | Explicit replacement: starting' 'This notification will be replaced using its numeric ID.')
send --replace-id="${id:-1}" --icon=emblem-ok-symbolic '30 | Explicit replacement: finished' 'The title, icon, and body changed without adding another history entry.'

for message in 'First grouped message' 'Second grouped message' 'Third grouped message'; do
	send --app-name='SwayNC Showcase Chat' --icon="$avatar" --category=im.received \
		"31 | $message" 'Same application name: inspect the collapsed stack and expand the group.'
done
send --hint=string:desktop-entry:org.gnome.Nautilus --category=transfer.complete \
	'32 | Desktop-entry lookup' 'Uses the file manager icon and application identity if its desktop entry is installed.'
send --hint=boolean:SWAYNC_BYPASS_DND:true '33 | Bypass DND' 'This example can appear even while DND is enabled. The script does not change DND.'

printf '%s\n' 'Showcase sent. Action listeners remain available for up to 3 minutes.' \
	'MPRIS needs a real media player; raw image-data is represented here by image-path.' \
	'Sound hints and action-icons are not showcased: SwayNC 0.12.6 does not render/play them.'
