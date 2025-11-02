#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <git-name> <git-email>"
    exit 1
fi

cp -r ./home/.local/ ./home/.config/ ./home/.bashrc ~/

sudo pacman -S --noconfirm --needed git

sh ./scripts/rust_setup.sh
sh ./scripts/paru_setup.sh
sh ./scripts/fd_setup.sh
sh ./scripts/dmenu_setup.sh
sh ./scripts/git_setup.sh "$1" "$2"
sh ./scripts/emacs_setup.sh
sh ./scripts/tmux_setup.sh

echo "Installation finished!"
