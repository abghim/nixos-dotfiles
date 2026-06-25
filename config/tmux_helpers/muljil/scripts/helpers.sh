#!/usr/bin/env bash

set -euo pipefail

fail() {
	local message="$1"

	tmux display-message "$message" >/dev/null 2>&1 || true
	printf '%s\n' "$message" >&2
	exit 1
}

require_commands() {
	local missing=()
	local command_name

	for command_name in "$@"; do
		if ! command -v "$command_name" >/dev/null 2>&1; then
			missing+=("$command_name")
		fi
	done

	if ((${#missing[@]} > 0)); then
		fail "muljil: missing dependency: ${missing[*]}"
	fi
}

muljil_projects_file() {
	local configured

	configured="$(tmux show-option -gqv '@muljil-projects-file' || true)"
	if [[ -n "$configured" ]]; then
		printf '%s\n' "$configured"
		return
	fi

	printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/muljil/projects.tsv"
}

ensure_projects_file() {
	local projects_file

	projects_file="$(muljil_projects_file)"
	mkdir -p "$(dirname "$projects_file")"
	touch "$projects_file"
	printf '%s\n' "$projects_file"
}

hide_cursor() {
	tput civis 2>/dev/null || true
	trap 'tput cnorm 2>/dev/null || true' EXIT
}

switch_or_create_session() {
	local session="$1"

	tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session"
	tmux switch-client -t "$session"
}
