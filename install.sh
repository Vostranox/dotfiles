#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <git-name> <git-email>"
    exit 1
fi

cp -r ./opt ./.local/ ./.config/ ./.bashrc ~/

sudo pacman -S --noconfirm --needed git

sh ./install/os/scripts/rust_setup.sh
sh ./install/os/scripts/paru_setup.sh
sh ./install/os/scripts/fd_setup.sh
sh ./install/os/scripts/dmenu_setup.sh
sh ./install/os/scripts/git_setup.sh "$1" "$2"
sh ./install/os/scripts/emacs_setup.sh
sh ./install/os/scripts/tmux_setup.sh
