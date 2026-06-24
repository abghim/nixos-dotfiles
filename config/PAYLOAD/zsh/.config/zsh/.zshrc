case $- in
   *i*) ;;
    *) return;;
esac

CONFIG_DIR="$HOME/.config/zsh"
source $CONFIG_DIR/path.sh
source $CONFIG_DIR/locale.sh
source $CONFIG_DIR/aliases.sh
source $CONFIG_DIR/autosuggest.sh
source $CONFIG_DIR/prompt.sh
source $CONFIG_DIR/misc.sh
source $CONFIG_DIR/tmux.sh
source $CONFIG_DIR/functions.sh

[[ -f "$HOME/.zshrc.local" ]] && source ~/.zshrc.local
