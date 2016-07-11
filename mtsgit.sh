#!/bin/bash
# Author: Mike Rodarte
#
# Interactive script for git shortcuts and scripts

. ~/.bashrc

gitDir=${gitDir:-'/var/www/html'}
prompt="MTSgit> "
default_branch=''
default_truth='master'
current_branch=''
version='1.09'

function display_prompt {
  set_current

  echo
  read -p $'\e[95m'"$prompt"$'\e[0m' choice
  case "$choice" in
    help) show_commands;;
    set) script_set;;
    truth) script_truth;;
    v) script_variables;;
    q) quit;;
    changes) git_changes;;
    create) git_create;;
    current) git_current;;
    delete) git_delete;;
    list) git_list;;
    log) git_log;;
    merge) git_merge;;
    push) git_push;;
    remote) git_remote;;
    reset) git_reset;;
    restore) git_restore;;
    save) git_save;;
    switch) git_switch;;
    undo) git_undo;;
    *) show_commands;;
  esac
}

function show_commands {
  echo 'Available commands'
  echo
  echo 'help                Show this command list'
  echo 'set                 Set the default branch name'
  echo 'truth               Set the default source of truth branch'
  echo 'v                   Show current variables'
  echo 'q                   Quit the program'
  echo
  echo 'changes             Show the files changed between two branches'
  echo 'create              Create a new branch'
  echo 'current             Display the current branch'
  echo 'delete              Delete a branch'
  echo 'list                List all local branches'
  echo 'log                 Display the Commit History'
  echo 'merge               Merge two branches'
  echo 'push                Push the current branch to origin'
  echo 'remote              Make a local branch remote'
  echo 'reset               Discard all changes and reset index and working tree'
  echo 'restore             Restore the latest stash'
  echo 'save                Stash the current changes'
  echo 'switch              Switch to a branch'
  echo 'undo                Undo a commit'

  display_prompt
}

function git_changes {
  cd $gitDir

  read -p "branch or commit name [${default_branch}]: " changed
  changed=${changed:-$default_branch}
  read -p "source of truth name [${default_truth}]: " truth
  truth=${truth:-$default_truth}

  git diff --name-only $changed $truth

  display_prompt
}

function git_create {
  cd $gitDir

  read -p "new branch name [${default_branch}]: " branch

  branch=${branch:-$default_branch}

  git checkout $default_truth
  git pull --no-rebase -v "origin"
  if [ $? -eq 1 ]; then
    echo 'Aborting branch create.'
  else
    git checkout -b $branch
    echo "Created $branch"
  fi

  display_prompt
}

function git_current {
  cd $gitDir

  set_current
  echo $current_branch

  display_prompt
}

function git_delete {
  cd $gitDir

  git checkout $default_truth

  read -p "branch name [${default_branch}]: " branch
  branch=${branch:-$default_branch}

  git branch -D $branch

  display_prompt
}

function git_list {
  cd $gitDir

  read -p "filter: " filter

  command='git branch'
  if [ ! -z $filter ]; then
    command="$command | grep $filter"
  fi

  eval ${command}

  display_prompt
}

function git_log {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  branch=${branch:-$default_branch}
  read -p "author (blank for all): " author

  git checkout $branch
  git pull
  git log --stat --graph --author=${author}

  display_prompt
}

function git_merge {
  cd $gitDir

  read -p "code branch name [${default_branch}]: " branchCode
  branchCode=${branchCode:-$default_branch}

  read -p "server branch name: " branchServer

  git checkout $branchServer
  git merge $branchCode
  if [ $? -gt 0 ]; then
    echo 'Aborting branch merge'
  else
    git pull --no-rebase -v "origin"
    if [ $? -gt 0 ]; then
      echo 'Aborting pull after merge'
    else
      git push "origin" $branchServer:$branchServer
    fi
  fi

  display_prompt
}

function git_push {
  cd $gitDir

  git pull
  if [ $? -eq 1 ]; then
    echo 'Aborting pull'
  else
    git push
    if [ $? -eq 1 ]; then
      echo 'Aborting push after pull'
    fi
  fi

  display_prompt
}

function git_remote {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  branch=${branch:-$default_branch}

  git push -u $branch

  display_prompt
}

function git_reset {
  cd $gitDir

  git reset --hard

  display_prompt
}

function git_restore {
  cd $gitDir

  git stash pop

  display_prompt
}

function git_save {
  cd $gitDir

  git stash save

  display_prompt
}

function git_switch {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  branch=${branch:-$default_branch}

  git checkout $branch
  git pull

  display_prompt
}

function git_undo {
  cd $gitDir

  git reset --soft HEAD

  display_prompt
}

function script_set {
  read -p "default branch [${current_branch}]: " default_branch
  default_branch=${default_branch:-$current_branch}

  echo "Set default branch to ${default_branch}"

  display_prompt
}

function script_truth {
  read -p "default source of truth branch: " default_truth

  echo "Set default source of truth to ${default_truth}"

  display_prompt
}

function script_variables {
  echo 'Current Variables'
  echo
  echo "gitDir: $gitDir"
  echo "prompt: $prompt"
  echo "default_branch: $default_branch"
  echo "default_truth: $default_truth"
  echo "current_branch: $current_branch"
  echo "version: $version"

  display_prompt
}

function set_current {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
}

function quit {
  echo 'Thank you for using MTSgit'
  exit 0
}

echo 'MTSgit: An interactive script for standard git commands'
echo "Version ${version}"
echo '                    by Mike Rodarte'
echo
echo 'Type help for a list of available commands.'
echo 'Press <Enter> to execute the command.'
echo

display_prompt

