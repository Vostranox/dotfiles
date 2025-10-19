#!/usr/bin/env bash

fd "" -IH --type f | \
fzf \
    --style full \
    --prompt 'Find> ' \
    --layout=reverse \
    --info=inline \
    --border \
    --margin=1 \
    --padding=1 \
    --preview='if [ -d {} ]; then eza -alg --color=always --group-directories-first {}; else bat --color=always --style=numbers {}; fi' \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --bind 'enter:become(emacsclient -n {1})' \
    --bind 'ctrl-o:become(open {1})'
