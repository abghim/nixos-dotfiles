#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

tmux set-option -gq @muljil-plugin-dir "$CURRENT_DIR"
tmux source-file "$CURRENT_DIR/muljil.conf"
