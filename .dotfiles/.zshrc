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

# Other
alias i='sudo dnf install'
alias d='sudo dnf'

# Git
alias c='git commit -m'
alias a='git add'
alias s='git status'
alias g='git'
alias p='git pull'
alias gp='git push'

export TERM=xterm
