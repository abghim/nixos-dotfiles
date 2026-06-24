#!/bin/bash

trap 'tput cnorm' EXIT
tput civis

session=$(gum input --padding "1 2" --placeholder "New project...")

if [[ -z "$session" ]]; then
	echo quit
	exit 1;
fi

src="$HOME/.config/tmux_helpers/projects.tsv"
tmp=$(mktemp "${src}.XXXXXX") &&
gawk -F'\t' -v OFS='\t' -v f="$session" '
$1 == f {
  $2 = systime()
  found = 1
}
{ print }
END {
  if (!found) print f, systime()
}
' "$src" > "$tmp" &&
mv "$tmp" "$src"

tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s $session
tmux switch-client -t "$session" 
tmux source-file ~/.tmux.conf


