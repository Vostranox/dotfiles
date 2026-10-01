#!/usr/bin/env bash

[[ -n ${FZF_PANE_SWITCH_LAYOUT:-} ]] || exit 0

case ${1:-} in
jump)
    printf 'jump'
    ;;
loaded)
    printf 'unbind(alt-j)'
    [[ $(tmux show-option -gqv @fzf_pane_switch_footer) == true ]] || exit 0

    footer=$'\033[1m[Enter]\033[0m \033[2mSwitch\033[0m'
    if [[ $(tmux show-option -gqv @fzf_pane_switch_preview-pane) != false ]]; then
        footer+=$'  ·  \033[1m[Ctrl-/]\033[0m \033[2mPreview\033[0m'
    fi
    footer+=$'  ·  \033[1m[Ctrl-O]\033[0m \033[2mJump\033[0m'
    if [[ $(tmux show-option -gqv @fzf_pane_switch_refresh) == true ]]; then
        footer+=$'  ·  \033[1m[Ctrl-R]\033[0m \033[2mRefresh\033[0m'
    fi
    printf '+change-footer(  %s  )' "$footer"
    ;;
esac
