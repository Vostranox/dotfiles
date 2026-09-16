fish_add_path ~/.cargo/bin ~/.local/bin ~/bin

set -gx VISUAL emacsclient -n
set -gx EDITOR emacsclient -n

if status is-interactive
    set -g fish_greeting

    function __sync_history --on-event fish_prompt
        history merge
    end

    set -gx FZF_CTRL_T_COMMAND "$HOME/.cargo/bin/fd --sort-by-depth --full-path --hidden --no-ignore --color=never --exclude .git"
    set -gx FZF_DEFAULT_OPTS "--layout=reverse --info=inline --border --margin=1 --padding=1 -i"

    alias ls 'eza -alg --color=always --group-directories-first'
    alias ll 'eza -lg --color=always --group-directories-first'
    alias e 'emacsclient -n'
    abbr -a vim nvim
    abbr -a tx 'tmux new -As dev'

    fzf --fish | source
    starship init fish | source
    zoxide init --cmd cd fish | source

    function wsl_zoxide_cdi --description 'cd to a directory from the Windows-side zoxide db'
        set -l dir (zoxide.exe query --list | fzf --height=30)
        or return
        test -n "$dir"; or return
        set -l target (wslpath -u $dir 2>/dev/null; or echo $dir)
        cd $target
    end

    bind alt-h backward-char
    bind alt-i forward-char
    bind alt-d backward-word
    bind alt-c forward-word

    bind alt-f beginning-of-line
    bind alt-o end-of-line
    bind alt-s kill-word
    bind alt-t backward-kill-word
    bind alt-T backward-kill-line
    bind alt-S kill-line

    bind ctrl-alt-f downcase-word
    bind ctrl-alt-o capitalize-word
    bind ctrl-alt-u upcase-word

    bind ctrl-h backward-kill-word
    bind ctrl-backspace backward-kill-word
end