#!/bin/bash

trap 'tput cnorm' EXIT
tput civis

session=$(gawk -F'\t' '{ print $2 "\t" $1 }' "$HOME/.config/tmux_helpers/projects.tsv" | sort -nr | cut -f2- | gum filter --padding "1 2" )

if [[ -z "$session" ]]; then
	echo quit
	exit 1;
fi

gum confirm --padding "1 2" "Erase $session from projects?" || exit 1;

gawk -F'\t' -v f="$session" '$1 != f' "$HOME/.config/tmux_helpers/projects.tsv" >projects.tsv.tmp && mv projects.tsv.tmp ~/.config/tmux_helpers/projects.tsv
