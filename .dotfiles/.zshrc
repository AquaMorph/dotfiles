HISTFILE=~/.zsh_history
HISTSIZE=99999999
SAVEHIST=99999999
setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -e
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

# Text Editor
alias emacs='emacs -nw'
alias e='emacs -nw'
alias i='sudo dnf install'
alias d='sudo dnf'
alias c='git commit -m '
alias g='git'
alias gp='git pull'

export TERM=linux
