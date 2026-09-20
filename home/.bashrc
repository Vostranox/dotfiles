[[ $- != *i* ]] && return

HISTCONTROL=ignoreboth
HISTSIZE=1000000
HISTFILESIZE=1000000

shopt -s histappend
shopt -s cmdhist
shopt -s lithist

PROMPT_COMMAND="history -a; history -n${PROMPT_COMMAND:+; $PROMPT_COMMAND}"

alias ls='eza -alg --color=always --group-directories-first'
alias ll='eza -lg --color=always --group-directories-first'
alias vim='nvim'
alias ..='cd ..'
alias e='emacsclient -n'
alias tx='tmux new -As dev'

command -v fzf >/dev/null && eval "$(fzf --bash)"
command -v starship >/dev/null && eval "$(starship init bash)"
command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd bash)"

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
