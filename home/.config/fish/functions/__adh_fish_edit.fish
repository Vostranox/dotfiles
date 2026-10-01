function __adh_fish_edit --argument-names action --description 'Selection operations for the adh modal layout'
    switch $action
        case normal
            if commandline --paging-mode
                commandline -f cancel
            else
                set -g fish_bind_mode default
                commandline -f end-selection suppress-autosuggestion repaint-mode
            end
        case word
            if commandline --selection-start >/dev/null
                commandline -f swap-selection-start-stop suppress-autosuggestion forward-word swap-selection-start-stop
            else
                commandline -f begin-selection suppress-autosuggestion forward-word swap-selection-start-stop
            end
        case line
            if commandline --selection-start >/dev/null
                if test (commandline --cursor) -eq (commandline --selection-start)
                    commandline -f swap-selection-start-stop down-line end-of-line swap-selection-start-stop
                else
                    commandline -f swap-selection-start-stop up-line beginning-of-line swap-selection-start-stop
                end
            else
                set -l lines (commandline)
                set -l line_number (commandline --line)
                if test -z "$lines[$line_number]"
                    commandline -f begin-selection forward-char-passive swap-selection-start-stop
                else
                    commandline -f beginning-of-line begin-selection end-of-line swap-selection-start-stop
                end
            end
        case indent
            set -l lines (commandline)
            set -l line_number (commandline --line)
            set -l indent (string match -r '^[ \t]*' -- "$lines[$line_number]")
            commandline --cursor (math (commandline --cursor) - (commandline --column) + 1 + (string length -- "$indent"))
        case copy
            set -l selection (commandline --current-selection | string collect -N)
            if test -n "$selection"
                printf %s "$selection" | __adh_fish_clipboard copy
                commandline -f begin-undo-group kill-selection yank end-undo-group end-selection
            end
        case save-yank
            set -g __adh_fish_yank_text (__adh_fish_clipboard paste | string collect -N)
            if not set -q __adh_fish_yank_text[1]
                set -g __adh_fish_yank_text $fish_killring[1]
            end
            if not set -q __adh_fish_yank_text[1]
                set -g __adh_fish_yank_text (commandline --current-selection | string collect -N)
            end
        case yank
            if set -q __adh_fish_yank_text[1]
                commandline --insert -- "$__adh_fish_yank_text"
            end
            set --erase __adh_fish_yank_text
        case backspace
            set -l selection (commandline --current-selection | string collect -N)
            if test -n "$selection"
                set -l start (commandline --selection-start)
                set -l end (commandline --selection-end)
                set -l chars (string split '' -- (commandline | string collect -N))
                set -e chars[-1]
                set -e chars[(math $start + 1)..$end]
                set -l replacement (printf %s $chars | string collect -N)
                commandline -f end-selection
                commandline --replace -- "$replacement"
                commandline --cursor $start
            else
                commandline -f end-selection backward-delete-char
            end
        case replace kill
            set -l selection (commandline --current-selection | string collect -N)
            if test -n "$selection"
                commandline -f kill-selection end-selection
            else if test "$action" = replace
                commandline -f end-selection delete-char
            else
                commandline -f end-selection kill-line
            end
    end
end
