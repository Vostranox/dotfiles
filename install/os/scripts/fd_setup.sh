#!/usr/bin/env bash
set -euo pipefail

mkdir -p "$HOME/opt"
if [[ ! -d "$HOME/opt/fd" ]]; then
    git clone -b simple_sort_by_depth https://github.com/Vostranox/fd.git "$HOME/opt/fd"
fi
pushd "$HOME/opt/fd" >/dev/null
git pull --ff-only
cargo install --path . --force
popd >/dev/null
