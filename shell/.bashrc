#!/usr/bin/env bash

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

########################################
## Aliases
########################################
alias gadd="git add"
alias gull="git pull"
alias gush="git push"
alias giff="git diff"
alias gcom="git commit --verbose"
alias glog="git log"
alias gmer="git merge"
alias gstu="git status"
alias gsta="git stash"
alias gwha="git whatchanged"
alias gche="git checkout"
alias gbra="git branch"
alias gfet="git fetch"

alias cac="conda activate"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

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


check_command_exists python
check_command_exists python3
if check_command_exists fzf; then
    alias fzf="fzf --reverse"
fi

if check_command_exists direnv; then
    eval "$(direnv hook bash)"
fi

if check_command_exists kubectl; then
    alias k="kubectl"
    
    function kns {
        kubectl config set-context --current --namespace="$1"
    }
    source <(kubectl completion bash)
fi

if check_command_exists helm; then
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


if check_command_exists hstr; then
    alias hh=hstr
    export HSTR_CONFIG=hicolor       # get more colors
    # ensure synchronization between bash memory and history file
    export PROMPT_COMMAND="history -a; history -n; ${PROMPT_COMMAND}"

    function hstrnotiocsti {
        { READLINE_LINE="$( { </dev/tty hstr "${READLINE_LINE}"; } 2>&1 1>&3 3>&- )"; } 3>&1;
        READLINE_POINT=${#READLINE_LINE}
    }


    # if this is interactive shell, then bind hstr to Ctrl-r (for Vi mode check doc)
    if [[ $- =~ .*i.* ]]; then bind -x '"\C-r": "hstrnotiocsti"'; fi
    export HSTR_TIOCSTI=n
fi

########################################
## PS1 prompt
########################################

function ps1_date {
    echo -n "$(date +"%H:%M")"
}

function ps1_git {
    BRANCH=$(git branch 2>/dev/null | grep '\*' | cut -c3-20 | tr -d "\n")
    N_STASHES=$(git stash list 2>/dev/null | wc -l)
    if [ "$N_STASHES" -eq 0 ]; then
        N_STASHES=""
    fi
       
    echo -ne "${CYAN}$BRANCH $N_STASHES${RESET}"
}

# modded from https://stackoverflow.com/questions/10406926/how-do-i-change-the-default-virtualenv-prompt
function ps1_virtualenv_info {
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi

    # also put changeps1: False to ~/.condarc to remove ps1 
    conda_env=$(basename "$CONDA_PREFIX")
    # conda_env=$(conda env list | grep "\*" | tr -s " " | cut -f1 -d " ")
    if [[ -n "$venv" ]] && [[ -n "$conda_env" ]]; then
        env_str="${conda_env}/${venv}"
    elif [[ -z "$venv" ]] && [[ -z "$conda_env" ]]; then
        env_str=""
    else
        # one of them is null: just concat them to get the non-null one (or empty)
        env_str="${conda_env}${venv}"
    fi

    echo -n "${env_str}"
}

function ps1_summary {
    # result of previous command with green (successful) or red (failure, nonzero exit)
    prev_cmd=$([[ "$?" -eq 0 ]] && echo -ne "${BR_GREEN}+" || echo -ne "${RED}-")
    # number of directories in directory stack (fixed for dirs with spaces)
    dir_stack_len="$(dirs -p | wc -l)"

    echo -ne "${BR_GREEN}${dir_stack_len}${prev_cmd}${RESET}"
}

# prevent python venv messing up the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

S=" "
export PS1="${INL_VIOLET}["'$(ps1_summary)'"${S}${INL_GOLD}\u@\h${INL_RESET}${S}${INL_VIOLET}\W${INL_RESET}${S}${INL_GRAY}"'$(ps1_virtualenv_info)'"${INL_RESET}${S}"'$(ps1_git)'"${INL_VIOLET}]>${INL_RESET} "    


########################################
## Misc Utility functions
########################################

function swap()         
{
    local TMPFILE=tmp.$$
    mv "$1" $TMPFILE && mv "$2" "$1" && mv $TMPFILE "$2"
}

function venv
{
    if [ -n "$1" ]; then
        _DIR="$1"
    else
        _DIR="./.venv"
    fi

    if ! [ -f "$_DIR/bin/activate" ]; then
        echo "Error: venv dir not found: $_DIR"
        return 1
    fi

    source "$_DIR/bin/activate"
    echo "$(readlink -f $_DIR) activated"
}

# pretty csv adapted from: https://www.stefaanlippens.net/pretty-csv.html
function pretty_csv {
    # cat "$@" | sed 's/,/ ,/g' | column -t -s, | less -S
    s="$IFS"
    if [ "$s" = "" ]; then
        s=","
    fi
    perl -pe "s/((?<=$s)|(?<=^))$s/ $s/g;" "$@" \
        | awk -F\" "{for (i=1; i<=NF; i+=2) gsub(/$s/,\"^\",\$i)} 1" OFS='"' \
	| column -t -s'^' \
        | less  -F -S -X -K
}


# https://stackoverflow.com/a/2709514/11579038
function remove_filename_spaces_recursively {
    find . -depth -name '* *' \
	    | while IFS= read -r f ; do mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)" ; done
}

# transform a windows path (C:/...) to valid wsl path (/mnt/c...)
function winpath_to_wsl {
    s="$1"
    echo "$s" | sed 's@\\@/@g' \
                    | (head -c 1 | tr A-Z a-z; sed 1q) \
                    | sed -E 's@^([a-z]):@/mnt/\1@'
}


# jump to the project root directory
function cdp {
    export CDP_PREV="${PWD}"
    TOP=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ "$?" == 0 ]; then
        cd "$TOP"
    fi
}
