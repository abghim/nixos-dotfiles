. "$HOME/.cargo/env"
trash() {
	TRASH_DIR=~/.trashfiles
	mkdir -p "$TRASH_DIR"
	for file in "$@"; do
		if [ -e "$file" ]; then
			mv "$file" "$TRASH_DIR/$(basename "$file").$(date +%s)"
			echo "Moved $file to trash."
		else
			echo "$RED$file not found.$NC"
		fi
	done
}

alias rm="trash"

hx() {
	emulate -L zsh -o extendedglob
  local after_dd=0 arg f

  for arg in "$@"; do
    if (( ! after_dd )); then
      [[ $arg == -- ]] && { after_dd=1; continue; }
      [[ $arg == -* ]] && continue
    fi

    # strip trailing :line[:col] suffixes
    f="$arg"
    while [[ $f == *:[0-9]## ]]; do f="${f%:[0-9]##}"; done

    [[ -f $f ]] || continue

		tstamp=$(date +"%Y%m%d-%H%M%S")
		backup="$HOME/.vim/backups/$(basename $f).$tstamp.hx.bak"

		touch $backup
		cat $f > $backup
  done

	command hx $@

}
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

ed() {
	emulate -L zsh -o extendedglob
  local after_dd=0 arg f

  for arg in "$@"; do
    if (( ! after_dd )); then
      [[ $arg == -- ]] && { after_dd=1; continue; }
      [[ $arg == -* ]] && continue
    fi

    # strip trailing :line[:col] suffixes
    f="$arg"
    while [[ $f == *:[0-9]## ]]; do f="${f%:[0-9]##}"; done

    [[ -f $f ]] || continue

		tstamp=$(date +"%Y%m%d-%H%M%S")
		backup="$HOME/.vim/backups/$(basename $f).$tstamp.ed.bak"

		touch $backup
		cat $f > $backup
  done

	command ed $@

}

# lazy-load thefuck on first use
fuck() {
	unfunction fuck
	eval "$(thefuck --alias fuck)"
	eval "fuck ${(@q)@}"
}

