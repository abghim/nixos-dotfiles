#!/bin/bash

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

command -v gum >/dev/null 2>&1 || { echo "gum is required"; exit 1; }
command -v stow >/dev/null 2>&1 || { echo "stow is required"; exit 1; }

OPTIONS=(
	"fish"
	"git"
	"emacs"
	"tmux"
	"tmux_helpers"
	"zsh"
	"zellij"
	"eza"
	"lazygit"
	"pulse"
	"alacritty"
	"cava"
	"ghostty"
	"ghostty.macos"
	"helix"
	"hypr"
	"kitty"
	"quickshell"
	"rio"
	"sway"
)

mapfile -t selections < <(gum choose --no-limit "${OPTIONS[@]}")

run_stow() {
	local mode="$1"
	local package_name

	for package_name in "${selections[@]}"; do
		[ -n "$package_name" ] || continue
		echo "$mode $package_name -> $HOME"
		stow $mode -d "$REPO_ROOT" -t "$HOME" "$package_name"
	done
}

if [ "${#selections[@]}" -gt 0 ]; then
	gum confirm "Install these packages?" && run_stow "--no-folding"
fi

if gum confirm "Install fonts to ~/.local/share/fonts?"; then
	font_dir="$HOME/.local/share/fonts"
	mkdir -p "$font_dir"
	echo "-n fonts -> $font_dir"
	gum confirm "Install fonts?" && stow -d "$REPO_ROOT" -t "$font_dir" fonts
fi

if gum confirm "Install HallaVim setup?" --default="No"; then
	curl https://gist.githubusercontent.com/abghim/e0fe0f7f5b97f807f6fb2890abbd4a60/raw/.hallavim-install.sh | bash
fi
