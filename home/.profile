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

export FZF_CTRL_T_COMMAND="$HOME/.cargo/bin/fd --sort-by-depth --full-path --hidden --no-ignore --color=never --exclude .git"
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline --border --margin=1 --padding=1 -i"

export EZA_CONFIG_DIR="$HOME/.config/eza"

export XMODIFIERS=@im=fcitx
export QT_QPA_PLATFORMTHEME=qt6ct
