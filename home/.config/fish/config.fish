fish_add_path ~/.cargo/bin ~/.local/bin ~/bin

set -gx EDITOR emacsclient
set -gx VISUAL emacsclient
set -gx TERMINAL ghostty

set -gx FZF_CTRL_T_COMMAND "$HOME/.cargo/bin/fd --sort-by-depth --full-path --hidden --no-ignore --color=never --exclude .git"
set -gx FZF_DEFAULT_OPTS "--layout=reverse --info=inline-right --border=rounded --margin=1 --padding=0,1 -i --pointer=▌ --marker=┃ --highlight-line --color=bg:#181818,bg+:#282828,fg:#8a8a95,fg+:#c8c8d5,hl:#95a99f,hl+:#95a99f,query:#c8c8d5,prompt:#95a99f,pointer:#95a99f,marker:#e8bf66,info:#6b7570,spinner:#6b7570,header:#6b7570,border:#3e3b3c,gutter:#181818,scrollbar:#3e3b3c"
set -gx EZA_CONFIG_DIR "$HOME/.config/eza"

if status is-interactive
    set -g fish_greeting

    function __sync_history --on-event fish_prompt
        history merge
    end

    alias ls 'eza -alg --color=always --group-directories-first'
    alias ll 'eza -lg --color=always --group-directories-first'
    alias e 'emacsclient -n'
    abbr -a vim nvim
    abbr -a tx 'tmux new -As dev'
    abbr -a .. 'cd ..'

    type -q fzf; and fzf --fish | source
    type -q starship; and starship init fish | source
    type -q zoxide; and zoxide init --cmd cd fish | source

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
