function __adh_fish_prompt_action --argument-names action --description 'Prompt shortcuts for tmux and directory selection'
    if test "$action" = directory
        if functions -q cdi; and command -q fzf
            cdi
            commandline -f repaint
        end
        return
    end

    if not set -q TMUX TMUX_PANE; or not command -q tmux
        if test "$action" = copy
            commandline -f pager-toggle-search
        end
        return
    end

    switch $action
        case copy
            command tmux copy-mode -t "$TMUX_PANE"
        case select
            command tmux copy-mode -t "$TMUX_PANE" \; send-keys -t "$TMUX_PANE" -X begin-selection
    end
end
