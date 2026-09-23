HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000

setopt hist_ignore_space
setopt hist_ignore_dups
setopt share_history

autoload -Uz compinit && compinit

alias ls='eza -alg --color=always --group-directories-first'
alias ll='eza -lg --color=always --group-directories-first'
alias vim='nvim'
alias ..='cd ..'
alias e='emacsclient -n'
alias tx='tmux new -As dev'

bindkey -e

command -v fzf >/dev/null && source <(fzf --zsh)
command -v starship >/dev/null && eval "$(starship init zsh)"
command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"

bindkey '\eh' backward-char
bindkey '\ei' forward-char
bindkey '\ed' backward-word
bindkey '\ec' forward-word
bindkey '\ef' beginning-of-line
bindkey '\eo' end-of-line
bindkey '\es' kill-word
bindkey '\et' backward-kill-word
bindkey '\eT' backward-kill-line
bindkey '\eS' kill-line

bindkey '\e^F' down-case-word
bindkey '\e^O' capitalize-word
bindkey '\e^U' up-case-word

bindkey '^H' backward-kill-word
