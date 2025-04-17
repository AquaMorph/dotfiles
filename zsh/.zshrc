autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST
PROMPT='%F{white}%n% @%m%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '

setopt appendhistory autocd extendedglob nomatch notify
unsetopt beep
bindkey -e
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

HISTFILE=~/.zsh_history
HISTSIZE=99999999
SAVEHIST=99999999


# Text Editor
alias emacs='emacs -nw'
alias e='emacs -nw'

# Other
alias i='sudo dnf install'
alias d='sudo dnf'
alias u='sh ~/bin/update.sh'
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
alias stash='git stash create; git stash push'
alias pop='git stash pop'


export TERM=xterm
export EDITOR=emacs

# Daisy build toolkit
GCC_PATH=~/dev/gcc-arm-none-eabi-10-2020-q4-major/bin
export PATH=$GCC_PATH:$PATH

# AM auto complete
autoload bashcompinit
bashcompinit
source "/home/aqua/.local/share/bash-completion/completions/am"
