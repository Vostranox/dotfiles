#!/usr/bin/env bash
set -euo pipefail

if ! command -v paru &> /dev/null; then
    git clone https://aur.archlinux.org/paru.git "$HOME/opt/paru"
    pushd "$HOME/opt/paru" >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
fi

/usr/bin/paru -S --needed --noconfirm $(<./resources/pkg/arch/paru.txt)

sudo systemctl start plocate-updatedb.service
sudo systemctl enable --now plocate-updatedb.timer
