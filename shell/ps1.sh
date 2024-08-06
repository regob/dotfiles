#!/usr/bin/env bash

## My PS1 prompt configuration, which looks like this:
## [2+ rego@tw dotfiles .venv main ]>

function ps1_git {
    # Check if the directory is a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        return
    fi
    
    local BRANCH=$(git branch --show-current 2>&1)

    # detached head - show commit hash
    if [ -z "$BRANCH" ]; then
        local BRANCH=$(git rev-parse @ | cut -c1-8)
    fi

    local n_stashes=$(git stash list 2>/dev/null | wc -l)
    
    # if remote branch exists check unpulled/unpushed commits
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 1>/dev/null 2>&1
    if [ "$?" -eq 0 ]; then
        local unpushed=$(git log @{u}.. --oneline 2>/dev/null | wc -l)
        local unpulled=$(git log ..@{u} --oneline 2>/dev/null | wc -l)
    else
        local unpulled=-
        local unpushed=-
    fi

    # append a + or - indicating dirty status
    local status=$(git status --porcelain)
    if [ -z "$status" ]; then
        local status=-
    else
        local status=+
    fi

    echo -ne "${CYAN}$BRANCH ${unpushed}/${unpulled}/${n_stashes}${status}${RESET}"
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
