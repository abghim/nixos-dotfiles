
colors=('#467159' '#C45A26' '#A04C62' '#285A6B' '#54846B')
tmuxcolor=${colors[ $RANDOM % ${#colors[@]} ]}
tmux set @lc "$tmuxcolor"
if [[ tmuxcolor == '' ]]; then
	tmux set @lc "#C44A26"
fi
