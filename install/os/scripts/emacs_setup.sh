#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d "$HOME/.emacs.d" ]]; then
    git clone https://github.com/Vostranox/adhoc-emacs.git "$HOME/.emacs.d"
else
    git -C "$HOME/.emacs.d" pull --ff-only
fi

"$HOME/.emacs.d/install.sh"
