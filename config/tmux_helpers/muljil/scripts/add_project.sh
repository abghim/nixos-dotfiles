#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Shared helpers keep the popup scripts plugin-relative.
. "$SCRIPT_DIR/helpers.sh"

hide_cursor
require_commands awk gum mktemp

projects_file="$(ensure_projects_file)"
session="$(gum input --padding "1 2" --placeholder "New project..." || true)"

if [[ -z "$session" ]]; then
	exit 0
fi

now="$(date +%s)"
tmp_file="$(mktemp "${projects_file}.XXXXXX")"

awk -F '\t' -v OFS='\t' -v project="$session" -v now="$now" '
$1 == project {
	$2 = now
	found = 1
}
{ print }
END {
	if (!found) {
		print project, now
	}
}
' "$projects_file" > "$tmp_file"

mv "$tmp_file" "$projects_file"
switch_or_create_session "$session"
