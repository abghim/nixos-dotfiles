#!/bin/bash

trap 'tput cnorm' EXIT
tput civis

session=$(gawk -F'\t' '{ print $2 "\t" $1 }' "$HOME/.config/tmux_helpers/projects.tsv" | sort -nr | cut -f2- | gum filter --padding "1 2" )

if [[ -z "$session" ]]; then
	echo quit
	exit 1;
fi

gawk -F'\t' -v OFS='\t' -v f=""$session"" '$1 == f { $2 = systime() } 1' ~/.config/tmux_helpers/projects.tsv > projects.tsv.tmp && mv projects.tsv.tmp ~/.config/tmux_helpers/projects.tsv

tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s $session
tmux switch-client -t "$session" 
tmux source-file ~/.tmux.conf


