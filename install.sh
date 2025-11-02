#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <git-name> <git-email>"
    exit 1
fi

mkdir -p "$HOME/opt"
cp -r ./home/.config ./home/.bashrc ./home/.Xresources ~/

./scripts/pacman_setup.sh
./scripts/rust_setup.sh
./scripts/paru_setup.sh
./scripts/fd_setup.sh
./scripts/dmenu_setup.sh
./scripts/git_setup.sh "$1" "$2"
./scripts/emacs_setup.sh
./scripts/tmux_setup.sh

echo "Installation finished!"
