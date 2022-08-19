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
alias u='sh ~/.config/scripts/update.sh'
alias dot='cd ~/dotfiles'
alias h='cd ~/git/cacolglazier.com/ && hugo server'
# Git
alias c='git commit -m'
alias a='git add'
alias ga='git add -A'
alias gu='git add -u'
alias s='git status'
alias g='git'
alias p='git pull'
alias gp='git push'
alias gd='git diff $(git rev-parse --abbrev-ref HEAD)'

export TERM=xterm

# Daisy build toolkit
GCC_PATH=~/dev/gcc-arm-none-eabi-9-2020-q2-update/bin
export PATH=$GCC_PATH:$PATH
