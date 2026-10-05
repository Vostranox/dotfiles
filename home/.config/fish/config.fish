fish_add_path ~/.cargo/bin ~/.local/bin ~/bin

if command -q emacsclient
    set -gx EDITOR emacsclient
    set -gx VISUAL emacsclient
end
if command -q ghostty
    set -gx TERMINAL ghostty
end

__adh_fish_configure_fzf
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"

if status is-interactive
    set -g fish_greeting

    set -l plain_theme (fish_config theme list 2>/dev/null | string match -ri '^none$')
    if set -q plain_theme[1]
        fish_config theme choose "$plain_theme[1]"
    end
    set -g fish_color_comment normal
    set -g fish_autosuggestion_enabled 0

    function __sync_history --on-event fish_prompt
        if test "$fish_private_mode" != 1
            builtin history merge
            __adh_import_bash_history
        end
    end

    if command -q eza
        alias ls 'eza -alg --color=always --group-directories-first'
        alias ll 'eza -lg --color=always --group-directories-first'
    else
        alias ll 'ls -l'
    end
    command -q emacsclient; and alias e 'emacsclient -n'
    command -q nvim; and abbr -a vim nvim
    command -q tmux; and abbr -a tx 'tmux new -As dev'
    abbr -a .. 'cd ..'

    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init --cmd cd fish | source

    set -g fish_key_bindings adh_fish_key_bindings
end
