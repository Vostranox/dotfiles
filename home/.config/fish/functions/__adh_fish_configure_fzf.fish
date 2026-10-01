function __adh_fish_configure_fzf --description 'Configure fzf using the tools and options available on this machine'
    set -l fd_command (command -s fd; or command -s fdfind)
    if set -q fd_command[1]
        set -gx FZF_CTRL_T_COMMAND (string escape -- "$fd_command")' --full-path --hidden --no-ignore --color=never --exclude .git'
        if command "$fd_command" --help 2>/dev/null | string match -q -- '*--sort-by-depth*'
            set -gx FZF_CTRL_T_COMMAND "$FZF_CTRL_T_COMMAND --sort-by-depth"
        end
    else
        set -e FZF_CTRL_T_COMMAND
    end

    set -gx FZF_DEFAULT_OPTS "--layout=reverse --info=inline-right --border=rounded --margin=1 --padding=0,1 --bind=ctrl-t:abort -i --pointer=▌ --marker=┃ --highlight-line --color=bg:#181818,bg+:#282828,fg:#8a8a95,fg+:#c8c8d5,hl:#95a99f,hl+:#95a99f,query:#c8c8d5,prompt:#95a99f,pointer:#95a99f,marker:#e8bf66,info:#6b7570,spinner:#6b7570,header:#6b7570,border:#3e3b3c,gutter:#181818,scrollbar:#3e3b3c"
    if not string match -q -- '*--bind=ctrl-a:down,ctrl-e:up*' "$FZF_CTRL_R_OPTS"
        set -gx FZF_CTRL_R_OPTS "$FZF_CTRL_R_OPTS --bind=ctrl-a:down,ctrl-e:up"
    end

    command -q fzf; or return 0

    command env FZF_DEFAULT_OPTS_FILE= fzf --filter= </dev/null >/dev/null 2>&1
    if test $status -gt 1
        set -gx FZF_DEFAULT_OPTS '--reverse --info=inline --border --bind=ctrl-t:abort -i'
    end

    status is-interactive; or return 0
    if command fzf --help 2>/dev/null | string match -q -- '*--fish*'
        command fzf --fish | source
    else if functions -q fzf_key_bindings
        fzf_key_bindings
    else
        for script in /usr/share/doc/fzf/examples/key-bindings.fish /usr/share/fzf/key-bindings.fish /usr/share/fzf/shell/key-bindings.fish
            if test -r "$script"
                source "$script"
                functions -q fzf_key_bindings; and fzf_key_bindings
                break
            end
        end
    end
end
