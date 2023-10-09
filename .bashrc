## .bashrc file

export PAGER=less
export EDITOR="emacs -nw -q"

# extended shell globbing
shopt -s extglob
shopt -s globstar

# history settings
export HISTSIZE=-1
export HISTFILESIZE=-1

# CDPATH and PATH in local config
# export CDPATH="$HOME:.."

########################################
## PS1 prompt
########################################

function ps1_date() {
    echo -n "$(date +"%H:%M")"
}

# unused in favor of pretty-git-prompt
function ps1_git() {
    BRANCH=$(git branch 2>/dev/null | grep '\*' | cut -c3-16 | tr -d "\n")
    echo -ne "$BRANCH"
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

function ps1_summary() {
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
## Utility functions
########################################

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

# pretty csv adapted from: https://www.stefaanlippens.net/pretty-csv.html
function pretty_csv {
    # cat "$@" | sed 's/,/ ,/g' | column -t -s, | less -S
    perl -pe 's/((?<=,)|(?<=^)),/ ,/g;' "$@" \
        | awk -F\" '{for (i=1; i<=NF; i+=2) gsub(/,/,";",$i)} 1' OFS='"' \
	| column -t -s';' \
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
