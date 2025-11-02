#!/usr/bin/env bash
set -euo pipefail

COMMIT="8b48986"
DMENU_DIR="$HOME/opt/dmenu"
PATCH_ABS="$(realpath ./resources/patches/dmenu/dmenu.patch)"

mkdir -p "$HOME/opt"
if [[ ! -d "$DMENU_DIR" ]]; then
  git clone https://git.suckless.org/dmenu "$DMENU_DIR"
fi

git -C "$DMENU_DIR" checkout --detach "$COMMIT"

if git -C "$DMENU_DIR" apply --reverse --check "$PATCH_ABS" >/dev/null 2>&1; then
  echo "Patch already applied; skipping."
else
  git -C "$DMENU_DIR" apply "$PATCH_ABS"
fi

pushd "$DMENU_DIR" >/dev/null
sudo make clean install
popd >/dev/null
