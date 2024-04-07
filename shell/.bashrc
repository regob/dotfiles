## .bashrc file

export PAGER=less
export EDITOR="emacs -nw -q"

# extended shell globbing
shopt -s extglob
shopt -s globstar


########################################
## Aliases
########################################
alias gadd="git add"
alias gull="git pull origin"
alias gush="git push origin"
alias giff="git diff"
alias gcom="git commit --verbose"
alias glog="git log"
alias gmer="git merge"
alias gstu="git status"
alias gsta="git stash"
alias gwha="git whatchanged"
alias gche="git checkout"
alias gbra="git branch"

alias cac="conda activate"

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
    # $1: command_name
    which "$1" >/dev/null 2>&1
    _cmd_found="$?"
    if [ "$_cmd_found" -eq 0 ]; then
        _msg="${BR_GREEN}$1${RESET} found at $(which $1)."
    else
        _msg="${RED}$1${RESET} not found."
    fi
    
    echo -e "$_msg"
    return "$_cmd_found"
}


check_command_exists python
check_command_exists python3
check_command_exists rg
if check_command_exists direnv; then
    eval "$(direnv hook bash)"
fi

if check_command_exists kubectl; then
    alias k="kubectl"
    
    function kns {
        kubectl config set-context --current --namespace="$1"
    }
fi

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
        { READLINE_LINE="$( { </dev/tty hstr ${READLINE_LINE}; } 2>&1 1>&3 3>&- )"; } 3>&1;
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

# unused in favor of pretty-git-prompt
function ps1_git {
    BRANCH=$(git branch 2>/dev/null | grep '\*' | cut -c3-16 | tr -d "\n")
    echo -ne "$BRANCH"
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
    dir_stack_len=$(echo $(dirs -p | wc -l))

    echo -ne "${BR_GREEN}${dir_stack_len}${prev_cmd}${RESET}"
}

# prevent python venv messing up the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

S=" "
export PS1="${INL_VIOLET}["'$(ps1_summary)'"${S}${INL_GOLD}\u@\h${INL_RESET}${S}${INL_VIOLET}\W${INL_RESET}${S}${INL_GRAY}"'$(ps1_virtualenv_info)'"${INL_RESET}${S}"'$(ps1_git)'"${INL_VIOLET}]>${INL_RESET} "    


########################################
## Misc Utility functions
########################################

function meta {

    USAGE="Usage: meta PROBLEM_CODE INPUT_FILE [-p CMD | -s NUMBER]

Other options:
  -p, --python CMD                use a given python interpreter
  -s, --sample NUMBER             show this many rows of the input and output
                                    if -1 provided, print the whole files
"
    
    POS_ARGS=()
    PY="pypy3.10"
    N_SAMPLE="10"
    
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -p|--python)
                PY="$2"
                shift
                shift
                ;;
            -s|--sample)
                N_SAMPLE="$2"
                if [[ "${N_SAMPLE}" -lt 0 ]]; then
                   N_SAMPLE=100000000
                fi
                shift
                shift
                ;;
            -h|--usage|--help)
                echo $USAGE
                shift
                ;;
            -*|--*)
                echo "Unknown option $1"
                exit 1
                ;;
            *)
                POS_ARGS+=("$1")
                shift
                ;;
        esac
    done
    
    set -- "${POS_ARGS[@]}" # restore positional parameters

    # not exactly 2 position arguments provided
    if [ -z "$1" ] || [ -z "$2" ] || [ -n "$3" ]; then 
        echo "Provide exactly 2 positional arguments!"
        echo "$USAGE"
        return 1
    fi

    cat "$2" | "$PY" "$1.py" > "$1_out.txt"
    # /usr/bin/time -f "%E"

    if [ "$?" -ne 0 ]; then
        echo "Error when running the program: Terminating."
        return 1
    fi

    IN_LINES=$(wc -l "$2")
    OUT_LINES=$(wc -l "$1_out.txt")
    echo "Input lines: $IN_LINES"
    echo "Output lines: $OUT_LINES"
    echo "In sample:"
    echo "--------------------"
    head -n ${N_SAMPLE} "$2"

    printf "\n"
    echo "Out sample:"
    echo "--------------------"
    head -n ${N_SAMPLE} "$1_out.txt"
}

function meta_init {
    if [[ $# -le 1 ]]; then
        echo "Usage: meta_init template_file CODE..."
    fi
    TEMPLATE="$1"
    shift

    for code in "$@"; do
        cp $TEMPLATE "${code}.py"
        touch "${code}_in.txt" "${code}_test.txt"
    done
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

# test with:
# mkdir -p "QQ WW"/"This is spaces"/"Windows bullshit"/"good_folder"; mkdir -p "QQ WW"/"good"; mkdir -p "QQ WW"/"a b c d e"; mkdir -p "goodfolder"/"bad folder"; mkdir -p "bad fol der"/"good_folder"/"h or ri ble folder"
function fix_dirnames {
    find . -depth -name '* *' \
	| while IFS= read -r f ; do mv -i "$f" "$(dirname "$f")/$(basename "$f"|tr ' ' _)" ; done
}

# find . -type d | awk -F ';' '/ / {print $1; gsub(" ", ""); print $1}' | sed -E 's/(.*)/"\1"/' | awk 'ORS=NR%2?FS:RS' | awk '{print gsub("/","/"), $0}' | sort -nr | cut -d '"' -f2- | sed 's/" "/\n/' | tr -d '"' | xargs -d "\n" -n 2 echo

# function rename_spaces {
#     echo "$@" | awk -F '\x00' '/ / {print $1; gsub(" ", ""); print $1}' | xargs -d "\n" -n 2 mv -i
# }


function winpath_to_wsl {
    s="$1"
    echo "$s" | sed 's@\\@/@g' \
                    | (head -c 1 | tr A-Z a-z; sed 1q) \
                    | sed -E 's@^([a-z]):@/mnt/\1@'
}
