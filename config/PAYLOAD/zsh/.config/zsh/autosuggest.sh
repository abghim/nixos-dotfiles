
autoload -Uz compinit && compinit

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
typeset -gA ZSH_HIGHLIGHT_STYLES

# Core tokens
ZSH_HIGHLIGHT_STYLES[command]='fg=none'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=none'
ZSH_HIGHLIGHT_STYLES[function]='fg=none'
ZSH_HIGHLIGHT_STYLES[alias]='fg=none'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=white'

# Options & arguments
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#f79652'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#f79652'
ZSH_HIGHLIGHT_STYLES[assign]='fg=#54846B'

# Paths
ZSH_HIGHLIGHT_STYLES[path]='fg=#f7b5c7'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#f7b5c7'

# Strings
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#94dff7'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#94dff7'

# Comments
ZSH_HIGHLIGHT_STYLES[comment]='fg=#54846B'

# Bracket levels
ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=cyan'
ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=yellow'
ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=magenta'


source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

ZSH_AUTOSUGGEST_STRATEGY="history"
