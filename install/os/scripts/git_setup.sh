#!/usr/bin/env bash
set -euo pipefail

git config --global user.name "$1"
git config --global user.email "$2"
git config --global core.editor "emacsclient -n"
git config --global init.defaultBranch main

DELTA_CFG="$HOME/.config/delta/config"
if [[ -f "$DELTA_CFG" ]] && ! git config --global --get-all include.path | grep -Fxq "$DELTA_CFG"; then
    git config --global --add include.path "$DELTA_CFG"
fi

bat cache --build

if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
    ssh-keygen -t ed25519 -C "$2"
else
    echo "[info] SSH key already exists — skipping generation."
fi
