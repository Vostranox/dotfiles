[[ $- != *i* ]] && return

case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=1000000
HISTFILESIZE=1000000

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

export VISUAL="emacsclient -n"
export EDITOR="emacsclient -n"

export FZF_CTRL_T_COMMAND='~/.cargo/bin/fd --sort-by-depth --full-path --hidden --no-ignore --color=never --exclude .git'
export FZF_DEFAULT_OPTS="--layout=reverse --info=inline --border --margin=1 --padding=1 -i"

alias ls='eza -alg --color=always --group-directories-first'
alias ll='eza -lg --color=always --group-directories-first'
alias vim='nvim'
alias ..='cd ..'
alias e='emacsclient -n'
alias tx='tmux new -As dev'
alias f='find_file'

eval "$(fzf --bash)"
eval "$(starship init bash)"
eval "$(zoxide init --cmd cd bash)"

wls_zoxide_cdi() {
    local dir target
    dir=$(zoxide.exe query --list | fzf --height=30) || return
    [ -z "$dir" ] && return
    target=$(wslpath -u "$dir" 2>/dev/null || echo "$dir")
    cd -- "$target" || return
}

bind -m emacs '"\eh": backward-char'
bind -m emacs '"\ei": forward-char'
bind -m emacs '"\ed": backward-word'
bind -m emacs '"\ec": forward-word'
bind -m emacs '"\ef": beginning-of-line'
bind -m emacs '"\eo": end-of-line'
bind -m emacs '"\es": kill-word'
bind -m emacs '"\et": backward-kill-word'
bind -m emacs '"\eT": unix-line-discard'
bind -m emacs '"\eS": kill-line'

bind -m emacs '"\e\C-f": downcase-word'
bind -m emacs '"\e\C-o": capitalize-word'
bind -m emacs '"\e\C-u": upcase-word'

bind -m emacs '"\C-h": backward-kill-word'
