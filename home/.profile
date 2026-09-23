path_prepend() {
    case ":$PATH:" in
        *":$1:"*) ;;
        *) PATH="$1${PATH:+:$PATH}" ;;
    esac
}

path_prepend "$HOME/bin"
path_prepend "$HOME/.local/bin"
path_prepend "$HOME/.cargo/bin"

export PATH
unset -f path_prepend

export EDITOR="emacsclient"
export VISUAL="emacsclient"
export TERMINAL="ghostty"

export FZF_CTRL_T_COMMAND="$HOME/.cargo/bin/fd --sort-by-depth --full-path --hidden --no-ignore --color=never --exclude .git"
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline-right --border=rounded --margin=1 --padding=0,1 -i --pointer=▌ --marker=┃ --highlight-line --color=bg:#181818,bg+:#282828,fg:#8a8a95,fg+:#c8c8d5,hl:#95a99f,hl+:#95a99f,query:#c8c8d5,prompt:#95a99f,pointer:#95a99f,marker:#e8bf66,info:#6b7570,spinner:#6b7570,header:#6b7570,border:#3e3b3c,gutter:#181818,scrollbar:#3e3b3c"

export EZA_CONFIG_DIR="$HOME/.config/eza"

export XMODIFIERS=@im=fcitx
export QT_QPA_PLATFORMTHEME=qt6ct
