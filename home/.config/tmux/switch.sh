#!/usr/bin/env bash
set -euo pipefail

case ${1:-} in
pane)
    cur=$(tmux display -p '#S:#{window_index}.#{pane_index}')
    items=$(tmux list-panes -a -F '#S:#{window_index}.#{pane_index}	#{pane_current_command}  #{b:pane_current_path}') ;;
window)
    cur=$(tmux display -p '#S:#{window_index}')
    items=$(tmux list-windows -a -F '#S:#{window_index}	#{window_name}  #{window_panes} pane#{?#{==:#{window_panes},1},,s}') ;;
*)
    echo "usage: $0 pane|window" >&2; exit 2 ;;
esac

items=$(printf '%s\n' "$items" | awk -F '\t' -v c="$cur" '$1 != c')
[[ -n "$items" ]] || { tmux display-message "no other ${1}s"; exit 0; }

printf '%s\n' "$items" | fzf --tmux center,62%,38% --margin=0 --delimiter='\t' --header="Select target $1." \
    --bind 'enter:execute-silent(tmux switch-client -t {1})+abort' || [[ $? -eq 130 ]]
