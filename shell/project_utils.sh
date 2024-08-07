#!/usr/bin/env bash

# jump to the project root directory
function cdp {
    export CDP_PREV="${PWD}"
    TOP=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ "$?" == 0 ]; then
        cd "$TOP"
    fi
}

# Run git-sync on all configured project in the list SYNC_PROJECT_LIST
function git_sync_all_projects {
    if [ -z "${SYNC_PROJECT_LIST}" ]; then
        echo "No projects found in SYNC_PROJECT_LIST. Nothing to do."
        return
    fi

    which git-sync >/dev/null 2>&1
    if [ "$?" -ne 0 ]; then
        echo "git-sync not found, please install using:"
        echo "git clone https://github.com/simonthum/git-sync"
        return
    fi

    for project_dir in "${SYNC_PROJECT_LIST[@]}"; do
        pushd "${project_dir}" >/dev/null
        echo -e "${BLUE}Syncing $(realpath "$PWD")...${RESET}"
        git-sync
        popd >/dev/null
        echo
    done

}

# Prints the git status summary for all repos in PROJECT_LIST
function git_project_statuses {
    if [ -z "${PROJECT_LIST}" ]; then
        echo "No projects found in PROJECT_LIST. Nothing to do."
        return
    fi

    for project_dir in "${PROJECT_LIST[@]}"; do
        git_status_summary "${project_dir}"
        echo ""
    done
}


# Prints a summary of the git repo passed
# The summary includes commits on the current/remote tracking branch
# and dirty files in the worktree/index
function git_status_summary {
    # Check if the argument is provided
    if [ -z "$1" ]; then
        echo "Usage: git_status_summary <path-to-git-repo>"
        return 1
    fi

    # Change to the directory
    pushd "$1" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Error: Unable to access directory '$1'."
        return 1
    fi

    # Check if the directory is a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        echo "Error: '$1' is not a Git repository."
        popd > /dev/null
        return 1
    fi

    echo -e "${BLUE}Checking $(realpath "$1")${RESET}"

    # Get the current branch name
    local branch=$(git branch --show-current)
    
    if [ -z "$branch" ]; then
        echo -e "${RED}HEAD is detached, no branch info available!${RESET}"
    else
        echo -e "Current branch: ${BR_GREEN}${branch}${RESET}"
        
        # if executed in one line, the return code would always be 0 due to the 'local' command
        local remote_branch
        remote_branch=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>&1)
        local remote_branch_exists=$?

        # show remote branch, and branch log diffs
        if [ "${remote_branch_exists}" -eq 0 ]; then
            echo -e "Remote branch: ${BR_GREEN}${remote_branch}${RESET}"
            
            # fetch remote: e.g. git fetch origin main
            git fetch $(echo ${remote_branch} | sed 's/\// /') >/dev/null 2>&1

            
            if [ $? -ne 0 ]; then
                echo -e "${RED}Fetching ${remote_branch} unsuccessful!${RESET}"
            fi

            # Check for unpushed commits
            local unpushed=$(git log @{u}.. --oneline 2>/dev/null)

            if [ -n "$unpushed" ]; then
                echo -e "${GREEN}Unpushed commits:${RESET}"
                echo "${unpushed}"
            fi

            # Check for unpulled commits
            local unpulled=$(git log ..@{u} --oneline 2>/dev/null)
            local PRINT_LIMIT=5

            if [ -n "$unpulled" ]; then
                echo -e "${GREEN}Unpulled commits:${RESET}"
                echo "${unpulled}" | head -n ${PRINT_LIMIT}
                
                # print # of commits truncated
                local total_unpulled=$(echo "${unpulled}" | wc -l)
                if [ ${total_unpulled} -gt ${PRINT_LIMIT} ]; then
                    echo -e "${GREEN}... $((total_unpulled - PRINT_LIMIT)) more ...${RESET}"
                fi
            fi
        else
            echo -e "${RED}No remote tracking branch exists.${RESET}"
        fi
    fi

    # List uncommitted and untracked files
    local git_status=$(git status --porcelain | sed 's/^/  /')

    if [ -n "${git_status}" ]; then
        echo -e "${GREEN}Status summary:${RESET}"
        echo "${git_status}"
    else
        echo -e "${GREEN}Status clear.${RESET}"
    fi

    # Return to the original directory
    popd >/dev/null

    return 0
}
