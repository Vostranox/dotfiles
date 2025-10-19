#!/usr/bin/env bash
set -euo pipefail

pushd "$HOME/opt/dmenu" >/dev/null
sudo make clean install
popd >/dev/null
