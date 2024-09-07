#!/usr/bin/env bash

########################################
## Some global settings
########################################

# path to this file's directory
# https://stackoverflow.com/a/246128/11579038
SHELL_DOTFILES_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# check if running in an interactive shell
[[ $- == *i* ]]
IS_INTERACTIVE="$?"

export PAGER=less

# if running as a daemon, use emacsclient instead of emacs as EDITOR
if ps -p $(pgrep emacs) 2>/dev/null | grep -- --daemon > /dev/null; then
    export EDITOR="emacsclient -nw"
else
    export EDITOR="emacs -nw -q"
fi

# extended shell globbing
shopt -s extglob
shopt -s globstar
# case insensitive globbing
shopt -s nocaseglob
# cd with only the directory name
shopt -s autocd

# turn off annoying tty features:
# Ctrl+S and Ctrl+Q to suspend and unsuspend input
# https://unix.stackexchange.com/a/12108/426499
stty -ixon

########################################
## Color definitions
########################################

# \x01 and \x02 enclose zero length characters for proper readline support
# https://stackoverflow.com/questions/32226139/escaping-zero-length-characters-in-bash
RESET='\x01\e[0;0m\x02'
RED='\x01\e[0;31m\x02'
GREEN='\x01\e[0;32m\x02'
YELLOW='\x01\e[0;33m\x02'
BLUE='\x01\e[38;5;39m\x02'
MAGENTA='\x01\e[0;35m\x02'
CYAN='\x01\e[38;5;87m\x02'
GRAY='\x01\e[0;37m\x02'
BR_GREEN="\x01\e[38;5;76m\x02"
VIOLET="\x01\e[38;5;9m\x02"

# inline sequences for coloring
INL_RED="\[\e[38;5;124m\]"
INL_BLUE='\[\e[38;5;39m\]'
INL_GRAY="\[\e[37m\]"
INL_GREEN="\[\e[32m\]"
INL_BR_GREEN="\[\e[38;5;76m\]"
# INL_WHITE="\[\e[0;31m\]"
INL_RESET="\[$(tput sgr0)\]"
INL_VIOLET="\[\e[38;5;9m\]" # 134
INL_PURPLE="\[\e[38;5;135m\]"
INL_LIGHT_BLUE="\[\e[38;5;159m\]" # 159
INL_MAGENTA="\[\e[38;5;201m\]"
INL_GOLD="\[\e[38;5;185m\]"

########################################
## Set up tools
########################################

function check_command_exists {
    # $1: command_name, $2 silent
    which "$1" >/dev/null 2>&1
    _cmd_found="$?"
    if [ "$_cmd_found" -eq 0 ]; then
        _msg="${BR_GREEN}$1${RESET} found at $(which "$1")."
    else
        _msg="${RED}$1${RESET} not found."
    fi
    
    # only display message if not in silent mode
    [ "$2" == 0 ] || echo -e "$_msg"
    return "$_cmd_found"
}


check_command_exists python 0
check_command_exists python3 0
if check_command_exists fzf 0; then
    alias fzf="fzf --reverse"
fi

if check_command_exists direnv 0; then
    eval "$(direnv hook bash)"
fi

if check_command_exists kubectl 0; then
    alias k="kubectl"
    
    function kns {
        kubectl config set-context --current --namespace="$1"
    }
    source <(kubectl completion bash)
fi

if check_command_exists helm 0; then
    source <(helm completion bash)
fi

function full_tooling_check {
    check_command_exists python
    check_command_exists python3
    check_command_exists fzf
    check_command_exists direnv
    check_command_exists kubectl
    check_command_exists helm
    check_command_exists hstr
    check_command_exists parallel
    check_command_exists rg
    check_command_exists ag
}

########################################
## History config
########################################

shopt -s histappend              # append new history items to .bash_history
export HISTCONTROL=ignorespace   # leading space hides commands from history
export HISTSIZE=-1               # unlimited history size
export HISTFILESIZE=-1           # unlimited history file size


# config adapted from https://github.com/dvorka/hstr
if check_command_exists hstr 0; then
    alias hh=hstr
    export HSTR_CONFIG=hicolor       # get more colors
    # ensure synchronization between bash memory and history file
    export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

    function hstrnotiocsti {
        { READLINE_LINE="$( { </dev/tty hstr -- ${READLINE_LINE}; } 2>&1 1>&3 3>&- )"; } 3>&1;
        READLINE_POINT=${#READLINE_LINE}
    }


    # if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
    if [[ $- =~ .*i.* ]]; then bind -x '"\e\C-r": "hstrnotiocsti"'; fi
    export HSTR_TIOCSTI=n
fi


########################################
## Load the other shell modules
########################################

source "${SHELL_DOTFILES_DIR}/ps1.sh"
source "${SHELL_DOTFILES_DIR}/project_utils.sh"
source "${SHELL_DOTFILES_DIR}/utils.sh"
source "${SHELL_DOTFILES_DIR}/aliases.sh"
