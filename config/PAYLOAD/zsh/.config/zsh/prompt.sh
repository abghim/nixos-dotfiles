setopt PROMPT_SUBST

BG=14191f

_prompt_phaser() {
	phaser-tty "$@" | perl -pe 's/\e\[[0-9;]*m/%{$&%}/g'
}

precmd() {
	local exit_code=$?
	(( exit_code == 0 )) && PROMPT_COLOR="467159" || PROMPT_COLOR="A04C62"

	local pth=$(pwd)
	local sliced="${pth##*/}"
	local len=${#sliced}
	if [[ $pth == $HOME ]]; then
		local len=1
	fi

	if [[ $len -ge 13 ]]; then
		local len=11
	fi

	local prompt_prefix=$'%{\e[48;2;20;25;31m%}'
	PROMPT="${prompt_prefix}%1~ ✨ $(_prompt_phaser "$BG" "$PROMPT_COLOR" $( expr 13 - $len ) ' ')$(_prompt_phaser "$PROMPT_COLOR" "$BG" 1 ' ') "
}

_prompt() {
	local emoji="✅"
	local string="$BASH_COMMAND"
	local cmd=${1%% *}

	case $cmd in
		cd | ls | pwd | mkdir | mv) emoji="📂" ;;
		vi | nano | vim | emacs | hx) emoji="✏️" ;;
		clang | make | 'clang++') emoji="🛠️";;
		python | py | python3) emoji="🐍";;
		brew) emoji="🍺";;
		rm | trash) emoji="🔥";;
		git) emoji="🔶";;
		sudo) emoji="🔑";;
		awk | sed | grep | egrep) emoji="🔍";;
		ftp | sftp | ssh | ping | nc) emoji="🌐";;
		cat | more | less) emoji="📚";;
		touch) emoji="✋";;
		rustc | cargo | rustfmt) emoji="🦀";;
		lldb) emoji="🔧";;
		echo) emoji="📢";;
		bash | sh | ksh | csh | tcsh | zsh) emoji="🐚";;
		*) emoji="✅";;
	esac

	local pth=$(pwd)
	local sliced="${pth##*/}"
	local len=${#sliced}
	if [[ $pth == $HOME ]]; then
		local len=1
	fi
	printf "\e[?25l\e[s\e[1A\e[$(( len + 2 ))G$emoji \e[u\e[?25h"

}

autoload -Uz add-zsh-hook
add-zsh-hook preexec _prompt
