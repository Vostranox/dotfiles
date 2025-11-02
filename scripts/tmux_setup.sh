#!/usr/bin/env bash
set -euo pipefail

TMUX_DIR="$HOME/.config/tmux"

if ! tmux has-session -t dev 2>/dev/null; then
    tmux new-session -d -s dev
fi

tmux source-file "$TMUX_DIR/tmux.conf"
