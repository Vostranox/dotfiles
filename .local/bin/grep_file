#!/usr/bin/env bash

rm -f /tmp/rg-fzf-{r,f}
RG_PREFIX="rg --column --line-number --no-heading --color=always --smart-case --hidden"
INITIAL_QUERY="${*:-}"
: | fzf --ansi --disabled --query "$INITIAL_QUERY" \
    --style full \
    --bind "start:reload($RG_PREFIX {q})+unbind(ctrl-r)" \
    --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
    --bind shift-up:preview-page-up,shift-down:preview-page-down \
    --color "hl:-1:underline,hl+:-1:underline:reverse" \
    --prompt 'Grep> ' \
    --delimiter : \
    --layout=reverse \
    --info=inline \
    --border \
    --margin=1 \
    --padding=1 \
    --preview 'bat --color=always {1} --highlight-line {2} --style=numbers' \
    --preview-window 'right,50%,border-bottom,+{2}+3/3,~3' \
    --bind 'enter:become(emacsclient -n {1})' \
    --bind 'ctrl-o:become(open {1})'
