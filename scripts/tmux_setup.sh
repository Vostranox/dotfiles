#!/usr/bin/env bash
set -euo pipefail

TMUX_DIR="$HOME/.config/tmux"

if [[ ! -d "$TMUX_DIR/plugins/tpm" ]]; then
    git clone https://github.com/tmux-plugins/tpm "$TMUX_DIR/plugins/tpm"
fi

if ! tmux has-session -t dev 2>/dev/null; then
    tmux new-session -d -s dev
fi

tmux source-file "$TMUX_DIR/tmux.conf"
tmux set-environment -g TMUX_PLUGIN_MANAGER_PATH "$TMUX_DIR/plugins/"
"$TMUX_DIR/plugins/tpm/bin/install_plugins"
