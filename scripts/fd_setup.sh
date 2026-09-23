#!/usr/bin/env bash
set -euo pipefail

if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
fi

if [[ ! -d "$HOME/opt/fd" ]]; then
    git clone -b simple_sort_by_depth https://github.com/Vostranox/fd.git "$HOME/opt/fd"
fi
pushd "$HOME/opt/fd" >/dev/null
git pull --ff-only
cargo install --path . --force
popd >/dev/null
