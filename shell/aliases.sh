#!/usr/bin/env bash

# Set up git aliases
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
alias greb="git rebase"
alias gtag="git tag"

# setup git autocompletion
if [ -f "/usr/share/bash-completion/completions/git" ]; then
  source /usr/share/bash-completion/completions/git
  __git_complete gadd _git_add
  __git_complete gull _git_pull
  __git_complete gush _git_push
  __git_complete giff _git_diff
  __git_complete gcom _git_commit
  __git_complete glog _git_log
  __git_complete gmer _git_merge
  __git_complete gstu _git_status
  __git_complete gsta _git_stash
  __git_complete gwha _git_whatchanged
  __git_complete gche _git_checkout
  __git_complete gbra _git_branch
  __git_complete gfet _git_fetch
  __git_complete greb _git_rebase
  __git_complete gtag _git_tag
fi

# General aliases
alias cac="conda activate"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
