#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <git-name> <git-email>"
    exit 1
fi

cd "$(dirname "$0")"

LINUX_ONLY=" environment.d fcitx5 fontconfig hypr qt6ct quickshell "

mkdir -p "$HOME/opt" "$HOME/.config"
cp ./home/.bashrc ./home/.bash_profile ./home/.profile ./home/.zprofile ./home/.zshrc ~/
for f in ./home/.config/*; do
    [[ $LINUX_ONLY == *" ${f##*/} "* ]] && continue
    cp -R "$f" "$HOME/.config/"
done

if ! command -v brew &> /dev/null && [[ ! -x /opt/homebrew/bin/brew ]]; then
    BREW_INSTALL=$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)
    /bin/bash -c "$BREW_INSTALL"
fi
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

brew install $(<./resources/pkg/macOS/brew.txt)

./scripts/rust_setup.sh
./scripts/fd_setup.sh
./scripts/git_setup.sh "$1" "$2"
./scripts/emacs_setup.sh
./scripts/tmux_setup.sh

echo "Installation finished!"
