## .bashrc file


## PS1 prompt

# TODO: rewrite colors with tput
RED="\[\e[31m\]"
GRAY="\[\e[37m\]"
GREEN="\[\e[32m\]"
BR_GREEN="\[\e[92m\]"
#WHITE="\[\e[0;31m\]"
RESET="\[$(tput sgr0)\]"

function ps1_date() {
    echo -n "$(date +"%H:%M")"
}

function ps1_git() {
    BRANCH=$(git branch 2>/dev/null | cut -c3-10 | tr -d "\n")
    echo -n "$BRANCH"
    # case $BRANCH in
    #     master | main)
    #         echo -n "$RED$BRANCH$RESET"
    #         ;;
    #     *)
    #         echo -n "$GREEN$BRANCH$RESET"
    #         ;;
    # esac
}

# modded from https://stackoverflow.com/questions/10406926/how-do-i-change-the-default-virtualenv-prompt
function virtualenv_info(){
    ## $(basename "$CONDA_PREFIX")
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi

    [[ -n "$venv" ]] && echo "(venv:$venv) "
}

# function dirsummary() {
    
# }

# prevent python venv messing up the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

export PS1="[\$(ps1_date) \u] [$BR_GREEN\$(virtualenv_info)$RESET] $GREEN\W$RESET $RED\$(pretty-git-prompt)$RESET>$RESET "
# export PS1="\$(ps1_date)/$GREEN\W$RESET/$RED\$(pretty-git-prompt)$RESET/\$$RESET "


# tw_prompt_color () {
# if [[ ! -z $TASKRC ]]; then
#   echo -n '\[\e[92m\] asdf  \[\033[34m\]'
# else
#   echo -e '\033[32m'
# fi
# }
# PS1='$(tw_prompt_color)iMac5K${RESET}'
