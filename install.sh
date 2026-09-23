#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <git-name> <git-email>"
    exit 1
fi

cd "$(dirname "$0")"

mkdir -p "$HOME/opt"
cp -r ./home/.config ./home/.local ./home/.bashrc ./home/.bash_profile ./home/.profile ./home/.zprofile ./home/.zshrc ~/

./scripts/pacman_setup.sh
./scripts/rust_setup.sh
./scripts/paru_setup.sh
./scripts/fd_setup.sh
./scripts/git_setup.sh "$1" "$2"
./scripts/emacs_setup.sh
./scripts/tmux_setup.sh

echo "Installation finished!"
