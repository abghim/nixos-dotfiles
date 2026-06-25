#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/helpers.sh"

hide_cursor
require_commands awk cut gum mktemp sort

projects_file="$(ensure_projects_file)"
session="$(
	awk -F '\t' 'NF { print $2 "\t" $1 }' "$projects_file" \
		| sort -nr \
		| cut -f2- \
		| gum filter --padding "1 2" || true
)"

if [[ -z "$session" ]]; then
	exit 0
fi

now="$(date +%s)"
tmp_file="$(mktemp "${projects_file}.XXXXXX")"

awk -F '\t' -v OFS='\t' -v project="$session" -v now="$now" '
$1 == project {
	$2 = now
}
{ print }
' "$projects_file" > "$tmp_file"

mv "$tmp_file" "$projects_file"
switch_or_create_session "$session"
