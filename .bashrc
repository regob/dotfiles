## .bashrc file

export PAGER=less
export EDITOR="emacs -nw -q"

# extended shell globbing
shopt -s extglob
shopt -s globstar

# history settings
export HISTSIZE=-1
export HISTFILESIZE=-1

## PS1 prompt
# TODO: rewrite colors with tput
function ps1_date() {
    echo -n "$(date +"%H:%M")"
}

# unused in favor of pretty-git-prompt
function ps1_git() {
    BRANCH=$(git branch 2>/dev/null | cut -c3-10 | tr -d "\n")
    echo -n "$BRANCH"
}

# modded from https://stackoverflow.com/questions/10406926/how-do-i-change-the-default-virtualenv-prompt
function ps1_virtualenv_info(){
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi

    # also put changeps1: False to ~/.condarc to remove ps1 
    conda_env=$(basename "$CONDA_PREFIX")
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
BR_GREEN="\x01\e[38;5;46m\x02"

# inline sequences for coloring
INL_RED="\[\e[31m\]"
INL_BLUE='\[\e[38;5;39m\]'
INL_GRAY="\[\e[37m\]"
INL_GREEN="\[\e[32m\]"
INL_BR_GREEN="\[\e[38;5;76m\]"
# INL_WHITE="\[\e[0;31m\]"
INL_RESET="\[$(tput sgr0)\]"
INL_VIOLET="\[\e[38;5;134m\]"
INL_PURPLE="\[\e[38;5;135m\]"
INL_MAGENTA="\[\e[38;5;201m\]"

function ps1_summary() {
    # result of previous command with green (successful) or red (failure, nonzero exit)
    prev_cmd=$([[ "$?" -eq 0 ]] && echo -ne "${BR_GREEN}+" || echo -ne "${RED}-")
    dir_stack_len=$(echo $(dirs | wc -w))

    echo -ne "${BLUE}${dir_stack_len}${prev_cmd}${RESET}"
}

# prevent python venv messing up the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

S="${INL_RESET}.${INL_RESET}"
export PS1="${INL_RED}["'$(ps1_summary)'"${S}${INL_RESET}\u@\h${INL_RESET}${S}${INL_BR_GREEN}\W${INL_RESET}${S}${INL_GRAY}"'$(ps1_virtualenv_info)'"${INL_RESET}${S}"'$(ps1_git)'"${INL_RED}]>${INL_RESET} "


function meta() {

    if [ -z "$3" ]; then
        PY="python3"
    else
        PY="$3"
    fi

    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "usage: meta problem_code input_file"
        return 1
    fi
    
    cat "$2" | "$PY" "$1.py" > "$1_out.txt"
    # /usr/bin/time -f "%E"

    if [ "$?" -ne 0 ]; then
        echo "Error when running the program."
        return 1
    fi

    IN_LINES=$(wc -l "$2")
    OUT_LINES=$(wc -l "$1_out.txt")
    echo "Input lines: $IN_LINES"
    echo "Output lines: $OUT_LINES"
    echo "In sample:"
    echo "--------------------"
    head -n 10 "$2"

    printf "\n"
    echo "Out sample:"
    echo "--------------------"
    head -n 10 "$1_out.txt"
}

# pretty csv from: https://www.stefaanlippens.net/pretty-csv.html
function pretty_csv {
    perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' "$@" | column -t -s, | less  -F -S -X -K
}
