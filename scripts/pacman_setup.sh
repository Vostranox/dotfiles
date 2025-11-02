#!/usr/bin/env bash
set -euo pipefail

sudo sed -i \
    -e 's/^#\?ParallelDownloads = .*/ParallelDownloads = 10/' \
    -e 's/^#Color/Color/' \
    -e 's/^#VerbosePkgLists/VerbosePkgLists/' \
    -e 's/^#DisableDownloadTimeout/DisableDownloadTimeout/' \
    /etc/pacman.conf

if grep -q "#ILoveCandy" /etc/pacman.conf; then
    sudo sed -i 's/^#ILoveCandy/ILoveCandy/' /etc/pacman.conf
elif ! grep -q "^ILoveCandy" /etc/pacman.conf; then
    sudo sed -i '/^Color/a ILoveCandy' /etc/pacman.conf
fi

sudo pacman -Sy --noconfirm archlinux-keyring
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm --needed base-devel git
