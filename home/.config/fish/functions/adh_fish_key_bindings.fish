function adh_fish_key_bindings --description 'Emacs insertion with the adh Meow normal layout'
    if not contains -- forward-char-passive (bind --function-names)
        fish_default_key_bindings
        bind \cx '__adh_fish_clipboard copy-commandline'
        bind \cv '__adh_fish_clipboard paste-commandline'
        return
    end

    bind --erase --all --preset
    fish_default_key_bindings -M insert
    fish_default_key_bindings -M default
    set -l paste begin-undo-group '__adh_fish_edit save-yank' kill-selection end-selection '__adh_fish_edit yank' end-undo-group

    for mode in insert default
        bind --erase --preset -M $mode ctrl-x
        bind --erase -M $mode alt-x
        bind -M $mode ctrl-x,ctrl-e edit_command_buffer
        bind -M $mode alt-e true
        bind -M $mode alt-v true

        bind -M $mode ctrl-a down-or-search
        bind -M $mode ctrl-e up-or-search
        bind -M $mode ctrl-f complete
        bind -M $mode ctrl-d delete-or-exit
        bind -M $mode ctrl-o '__adh_fish_prompt_action directory'
        bind -M $mode ctrl-s '__adh_fish_prompt_action copy'
        bind -M $mode alt-n '__adh_fish_prompt_action select'
        bind -M $mode ctrl-g end-selection cancel
        bind -M $mode ctrl-t end-selection cancel
        bind -M $mode ctrl-l clear-screen
        bind -M $mode ctrl-u $paste
        bind -M $mode ctrl-v '__adh_fish_clipboard paste-commandline'
        bind -M $mode ctrl-h '__adh_fish_edit word'
        bind -M $mode backspace begin-undo-group '__adh_fish_edit backspace' end-undo-group
        bind -M $mode shift-backspace begin-undo-group '__adh_fish_edit backspace' end-undo-group
        bind -M $mode ctrl-backspace backward-kill-word
        bind -M $mode ctrl-space begin-selection

        bind -M $mode alt-h backward-char
        bind -M $mode alt-i forward-char
        bind -M $mode alt-d backward-word
        bind -M $mode alt-c forward-word
        bind -M $mode alt-f beginning-of-line
        bind -M $mode alt-o end-of-line
        bind -M $mode alt-l clear-screen
        bind -M $mode alt-s kill-word
        bind -M $mode alt-t backward-kill-word
        bind -M $mode alt-T backward-kill-line
        bind -M $mode alt-S kill-line
        bind -M $mode alt-\< suppress-autosuggestion end-of-buffer
        bind -M $mode alt-\> beginning-of-buffer
        bind -M $mode ctrl-alt-f downcase-word
        bind -M $mode ctrl-alt-o capitalize-word
        bind -M $mode ctrl-alt-u upcase-word

        if functions -q fzf-file-widget
            bind -M $mode alt-enter fzf-file-widget
        end
        bind -M $mode -m insert ctrl-c end-selection clear-commandline repaint-mode
        for key in enter ctrl-j ctrl-m ctrl-enter
            bind -M $mode -m insert $key end-selection execute
        end
    end

    for key in escape ctrl-\[
        bind -M insert $key '__adh_fish_edit normal'
        bind -M default $key end-selection cancel
    end

    bind --erase -M default ''
    bind -M default h backward-char-passive
    bind -M default a down-or-search
    bind -M default e up-or-search
    bind -M default i forward-char-passive
    bind -M default j beginning-of-line
    bind -M default f '__adh_fish_edit indent'
    bind -M default o end-of-line
    bind -M default d backward-word
    bind -M default c suppress-autosuggestion forward-word
    bind -M default k '__adh_fish_edit line'
    bind -M default p '__adh_fish_edit word'
    bind -M default n begin-selection
    bind -M default '!' begin-selection
    bind -M default r swap-selection-start-stop
    bind -M default l '__adh_fish_edit copy'
    bind -M default u $paste
    bind -M default b end-selection undo
    bind -M default B end-selection redo
    bind -M default -m insert t end-selection repaint-mode
    bind -M default -m insert s '__adh_fish_edit replace'
    bind -M default -m insert '?' '__adh_fish_edit replace'
    bind -M default w '__adh_fish_edit kill'
    bind -M default z end-selection kill-word
    bind -M default x end-selection kill-whole-line
    bind -M default -m insert A end-selection insert-line-under repaint-mode
    bind -M default -m insert E end-selection insert-line-over repaint-mode
    bind -M default '+' beginning-of-buffer
    bind -M default - suppress-autosuggestion end-of-buffer

    set -g fish_cursor_default block
    set -g fish_cursor_insert line
    set -g fish_cursor_selection_mode exclusive
    set -g fish_cursor_end_mode exclusive
    fish_vi_cursor
    set -g fish_bind_mode insert

    function __adh_fish_reset_mode --on-event fish_postexec
        set -g fish_bind_mode insert
    end
end
