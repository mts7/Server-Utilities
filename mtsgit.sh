#!/bin/bash
# Author: Mike Rodarte
#
# Interactive script for git shortcuts and scripts

if [ -e ~/.bashrc ]; then
  . ~/.bashrc
fi

# Variables BEGIN
# User Variables
git_dir=${git_dir:-'/var/www/html'}
default_truth='master'
default_prod_server='production'
default_remote='origin'
# Variables END

#######################################
# Display the main menu prompt
# Globals:
#   prompt
#   current_branch
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function display_prompt {
  set_current

  local choice

  echo
  read -p $'\e[95m'"$prompt"$'\e[36m'" $current_branch"$'\e[95m'"> "$'\e[0m' choice
  datetimestamp
  echo -e "\e[35m$stamp\e[0m $choice\e[0m" >> ${history_file}
  case "$choice" in
    dir) script_dir;;
    help) show_commands;;
    history) script_history;;
    set) script_set;;
    truth) script_truth;;
    v) script_variables;;
    q) quit;;
    add) git_add;;
    changes) git_changes;;
    commit) git_commit;;
    create) git_create;;
    current) git_current;;
    delete) git_delete;;
    deploy) git_deploy;;
    deployment) git_deployment;;
    exec) git_exec;;
    list) git_list;;
    log) git_log;;
    merge) git_merge;;
    message) git_message;;
    pull) git_pull;;
    push) git_push;;
    remote) git_remote;;
    reset) git_reset;;
    restore) git_restore;;
    revert) git_revert;;
    save) git_save;;
    server) git_server;;
    servers) git_servers;;
    status) git_status;;
    switch) git_switch;;
    track) git_track;;
    undo) git_undo;;
    untrack) git_untrack;;
    var) func_var;;
    *) echo -e "\e[91mUnknown command $choice\e[0m";show_commands;;
  esac
}

#######################################
# Show available commands
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function show_commands {
  echo 'Available commands'
  echo
  echo 'dir                 Set the git directory'
  echo 'help                Show this command list'
  echo 'set                 Set the default branch name'
  echo 'truth               Set the default source of truth branch'
  echo 'v                   Show current variables'
  echo 'q                   Quit the program'
  echo
  echo 'add                 Add one or more files to staging'
  echo 'changes             Show the files changed between two branches'
  echo 'commit              Commit changes to local branch or repository'
  echo 'create              Create a new branch'
  echo 'current             Display the current branch'
  echo 'delete              Delete a branch*'
  echo 'deploy              Merge and push a branch to a server'
  echo 'deployment          Add a remote (deployment) branch to use with deploy'
  echo 'exec                Make a file executable'
  echo 'list                List branches'
  echo 'log                 Display the Commit History of a branch*'
  echo 'merge               Merge two branches*'
  echo 'message             Update a message to the last commit'
  echo 'pull                Fetch or merge changes with remote server'
  echo 'push                Push the current branch to origin'
  echo 'remote              Make a local branch* remote'
  echo 'reset               Discard all changes and reset index* and working tree'
  echo 'restore             Restore the latest stash'
  echo 'revert              Revert a commit*'
  echo 'save                Stash the current changes'
  echo 'server              Change the default remote server'
  echo 'servers             List the remotes'
  echo 'status              List the files changed and need to be added'
  echo 'switch              Switch to a branch*'
  echo 'track               Switch tracking to new remote branch'
  echo 'undo                Undo a commit'
  echo 'untrack             Stop tracking a remote branch'
  echo 'var                 Display a variable'
  echo
  echo '* shows commands that accept the menu parameter at some branch prompts'

  display_prompt
}

#######################################
# Add files to git
# Globals:
#   git_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_add {
  cd ${git_dir}

  local files
  local i
  local rc
  
  read -e -p 'file name: ' files
  if [ -n "$files" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${files} ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    # show result of "git status" to help indicate what should be added
    if [ ${i} -eq 1 ]; then
      git status -s
    fi
    read -e -p $'\e[91mPlease specify a file name: \e[0m' files
    if [ -n "$files" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${files} ]; then
    echo -e "\e[91mA file name was not specified"
  else
    git add ${files}
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] with add"
    fi
  fi

  display_prompt
}

#######################################
# Display changes between truth and
#   branch or commit
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   menu_value
#   default_truth
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_changes {
  cd ${git_dir}

  local changed
  local truth
  local rc

  read -p "branch or commit name [${default_branch}]: " changed
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$changed\e[0m" >> ${history_file}
  changed=${changed:-$default_branch}

  if [ "$changed" = "menu" ]; then
    menu_branch
    changed="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    changed=${changed:-$default_branch}
  fi

  read -p "source of truth name [${default_truth}]: " truth
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> ${history_file}
  truth=${truth:-$default_truth}

  git diff --name-only ${changed} ${truth}
  rc=$?
  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] with diff"
  fi

  display_prompt
}

#######################################
# Commit files to git
# Globals:
#   git_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_commit {
  cd ${git_dir}

  local message
  local i
  local rc

  read -p "message: " message
  if [ -n "$message" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${message} ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a commit message: \e[0m' message
    if [ -n "$message" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${message} ]; then
    echo -e "\e[91mPlease commit with a message"
  else
    git commit -a -m "$message"
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] with commit"
    fi
  fi

  display_prompt
}

#######################################
# Create a new branch
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   default_truth
#   pull_result
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_create {
  cd ${git_dir}

  local remote
  local branch
  local rc

  read -p 'from remote? [y|n] ' remote
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m${remote}\e[0m" >> ${history_file}

  read -p "new branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  git checkout ${default_truth}
  rc=$?
  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] with checking out $default_truth"
  else
    func_pull
    rc=${pull_result}
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting branch create."
    else
      if [ "y" = "${remote}" ]; then
        git checkout --track ${default_remote}/${branch}
      else
        git checkout -b ${branch}
      fi
      rc=$?
      if [ ${rc} -gt 0 ]; then
        echo -e "\e[91mError [$rc]; failed to create branch"
      else
        echo -e "\e[92mCreated $branch"
      fi
    fi
  fi

  display_prompt
}

#######################################
# Set and display the current branch
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_current {
  cd ${git_dir}

  set_current
  echo -e "\e[36m$current_branch"

  display_prompt
}

#######################################
# Delete a branch
# Globals:
#   git_dir
#   default_truth
#   stamp
#   history_file
#   default_branch
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_delete {
  cd ${git_dir}

  local branch
  local to_delete
  local answer
  local rc

  git checkout ${default_truth}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  to_delete=1
  if [ "$branch" = ${default_truth} ]; then
    echo -e "\e[101mDeleting the default truth branch is not recommended."
    read -p "Are you sure you want to delete the source of truth? [y/n]: " answer
    if [ "$answer" = "y" ]; then
      to_delete=1
    elif [ "$answer" = "n" ]; then
      to_delete=0
    else
      to_delete=0
      echo -e "\e[91mUnknown answer $answer"
    fi
  fi

  if [ ${to_delete} -eq 1 ]; then
    git branch -D ${branch}
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not delete branch $branch"
    fi
  else
    echo -e "\e[93mSkipping deletion of $branch"
  fi

  display_prompt
}

#######################################
# Deploy code to default remote and
#   default production remote
# Globals:
#   git_dir
#   stamp
#   history_file
#   default_branch
#   menu_value
#   prefix
#   default_prod_server
#   default_truth
#   default_deploy
#   default_remote
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_deploy {
  cd ${git_dir}

  local branch_code
  local branch_server
  local i
  local command
  local default_deploy
  local deploy_server

  read -p "code branch name [${default_branch}]: " branch_code
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch_code\e[0m" >> ${history_file}
  branch_code=${branch_code:-$default_branch}

  if [ "$branch_code" = "menu" ]; then
    menu_branch
    branch_code="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch_code=${branch_code:-$default_branch}
  fi

  read -p "server branch name: " branch_server
  if [ -n "$branch_server" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branch_server\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${branch_server} ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    if [ ${i} -eq 1 ] && [ ! -z "$prefix" ]; then
      echo -e "\e[93mDid you mean one of these branches?\e[0m"
      # suggest a branch name
      command="git branch -r | egrep '${prefix}-[A-Z]+[0-9]*\b$'"
      eval ${command}
    fi
    read -p $'\e[91mPlease specify a server branch name: \e[0m' branch_server
    if [ -n "$branch_server" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$branch_server\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${branch_server} ]; then
    echo -e "\e[91mError: A branch name must be provided\e[0m"
  else
    default_deploy="${default_prod_server}/${default_truth}"
    read -p "deployment server branch name [${default_deploy}]: " deploy_server
    deploy_server=${deploy_server:-$default_deploy}

    script_comment "Switching to $branch_server"
    git checkout ${branch_server}
    script_comment "Merging $branch_code to $branch_server"
    git merge ${branch_code}
    script_comment "Pushing ${default_truth} to $branch_server"
    git push ${default_remote} ${default_truth}:${default_truth}
    script_comment "Switching to $deploy_server"
    git checkout ${deploy_server}
    script_comment "Merging $branch_code to $deploy_server"
    git merge ${branch_code}
    script_comment "Pushing ${default_truth} to $deploy_server"
    git push ${default_prod_server} ${default_truth}:${default_truth}
    script_comment "Switching to $branch_server"
    git checkout ${branch_server}
  fi

  display_prompt
}

#######################################
# Set the default deployment remote
# Globals:
#   git_dir
#   default_prod_server
#   default_deploy
#   stamp
#   history_file
#   default_truth
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_deployment {
  cd ${git_dir}

  local default_deploy
  local deploy_server
  local git_path
  local rc

  default_deploy="${default_prod_server}"
  read -p "deployment server branch name [${default_deploy}]: " deploy_server
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$deploy_server\e[0m" >> ${history_file}
  deploy_server=${deploy_server:-$default_deploy}

  read -p "git path (include ssh://user@host:port/path): " git_path
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$deploy_server\e[0m" >> ${history_file}
  if [ -z "$git_path" ]; then
    echo -e "\e[91mError: A git path must be added\e[0m"
  else
    git remote add ${deploy_server} ${git_path}
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] adding remote branch\e[0m"
    else
      git push ${deploy_server} +${default_truth}:refs/heads/${default_truth}
      rc=$?
      if [ ${rc} -gt 0 ]; then
        echo -e "\e[91mError pushing to deployment server\e[0m"
      fi
    fi
  fi

  display_prompt
}

#######################################
# Make a file executable
# Globals:
#   git_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_exec {
  cd ${git_dir}

  local file

  read -e -p 'file to make executable: ' file
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$file\e[0m" >> ${history_file}

  if [ -e "$file" ]; then
    git update-index --chmod=+x ${file}
  else
    echo -e "\e[91mError: file ${file} does not exist\e[0m"
  fi

  display_prompt
}

#######################################
# List local or remote branches
# Globals:
#   git_dir
#   stamp
#   history_file
#   default_truth
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_list {
  cd ${git_dir}

  local remote
  local command
  local filter
  local rc

  read -p 'remote [y/n]: ' remote
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$remote\e[0m" >> ${history_file}

  command='git branch'

  read -p "filter: " filter
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$filter\e[0m" >> ${history_file}

  if [ "$remote" = "y" ]; then
    command="$command -r"

    # check for new branches that were pushed since the last pull
    echo -e "\e[36mChecking for remote branches...\e[0m"
    echo
    git checkout ${default_truth}
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] checking out $default_truth\e[0m"
    else
      func_pull
    fi
    echo
    echo -e "\e[33mRemote Branches\e[0m"
  elif [ "$remote" != "n" ]; then
    echo -e "\e[91mInvalid response\e[0m"
  else
    echo
    echo -e "\e[33mLocal Branches\e[0m"
  fi

  if [ ! -z ${filter} ]; then
    command="$command | grep $filter"
  fi

  eval ${command}
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not list branches\e[0m"
  fi

  display_prompt
}

#######################################
# Show log for branch with author,
#   file, and days ago options
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_log {
  cd ${git_dir}

  local branch
  local author
  local file
  local default_days
  local days
  local days_ago
  local file_cmd
  local rc

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  read -p "author (blank for all): " author
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$author\e[0m" >> ${history_file}

  read -e -p "file relative to repo root (blank for all): " file
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$file\e[0m" >> ${history_file}

  default_days=7
  read -p "days ago [${default_days}]: " days
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$days\e[0m" >> ${history_file}

  if [ "$days" -eq "$days" ] > /dev/null 2>&1
  then
    days=${days}
  else
    days=${default_days}
  fi
  days_ago=$(date --date="$days days ago" +"%Y"-"%m"-"%d")

  git checkout ${branch}
  rc=$?
  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not checkout $branch\e[0m"
  else
    file_cmd=''
    if [ -n "$file" ]; then
      file_cmd=" --follow -p $file"
    fi
    git log --stat --graph --author=${author} --since="$days_ago" ${file_cmd}
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not get log\e[0m"
    fi
  fi

  display_prompt
}

#######################################
# Merge two branches
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   menu_value
#   prefix
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_merge {
  cd ${git_dir}

  local branch_code
  local branch_server
  local i
  local command

  read -p "code branch name [${default_branch}]: " branch_code
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch_code\e[0m" >> ${history_file}
  branch_code=${branch_code:-$default_branch}

  if [ "$branch_code" = "menu" ]; then
    menu_branch
    branch_code="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch_code=${branch_code:-$default_branch}
  fi

  read -p "server branch name: " branch_server
  if [ -n "$branch_server" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branch_server\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${branch_server} ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    if [ ${i} -eq 1 ] && [ ! -z "$prefix" ]; then
      echo -e "\e[93mDid you mean one of these branches?\e[0m"
      # suggest a branch name
      command="git branch -r | egrep '${prefix}-[A-Z]+[0-9]*\b$'"
      eval ${command}
    fi
    read -p $'\e[91mPlease specify a server branch name: \e[0m' branch_server
    if [ -n "$branch_server" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$branch_server\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${branch_server} ]; then
    echo -e "\e[91mA server branch name must be specified\e[0m"
  else
    func_merge ${branch_code} ${branch_server}
  fi

  display_prompt
}

#######################################
# Update the message for the latest
#   commit
# Globals:
#   git_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_message {
  cd ${git_dir}

  local message
  local rc

  read -p 'new commit message: ' message
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> ${history_file}

  if [ -n "$message" ]; then
    git commit --amend -m "$message"

    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError amending the commit message\e[0m"
    fi
  fi

  display_prompt
}

#######################################
# Pull from git and display the prompt
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_pull {
  func_pull

  display_prompt
}

#######################################
# Push to git and display the prompt
# Globals:
#   git_dir
#   default_remote
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_push {
  cd ${git_dir}

  local default_server
  local server

  default_server=${default_remote}
  read -p "server [$default_server]: " server
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$server\e[0m" >> ${history_file}
  server=${server:-$default_server}

  func_push ${server}

  display_prompt
}

#######################################
# Push a branch to a remote
# Globals:
#   git_dir
#   default_remote
#   default_branch
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_remote {
  cd ${git_dir}

  local default_server
  local server
  local branch
  local rc

  default_server=${default_remote}
  read -p "server [$default_server]: " server
  server=${server:-$default_server}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ -z ${branch} ]; then
    echo -e "\e[91Please enter a branch name\e[0m"
  else
    git push -u ${default_server} ${branch}
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] making branch $branch remote\e[0m"
    fi
  fi

  display_prompt
}

#######################################
# Hard reset a branch to a commit
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_reset {
  cd ${git_dir}

  local branch
  local rc
  local commit
  local answer

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ "$branch" != "$current_branch" ]; then
    git checkout ${branch}
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] checking out $branch"
      echo "using $current_branch instead of $branch"
      branch="$current_branch"
    fi
    script_set_current
  fi

  read -p 'commit name: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> ${history_file}

  if [ "$commit" = "menu" ]; then
    menu_commit
    commit="$menu_value"
  fi

  read -p "Are you sure you want to reset $branch? [y/n] " answer
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$answer\e[0m" >> ${history_file}

  if [ "$answer" = 'y' ]; then
    git reset --hard ${commit}
    rc=$?

    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] with reset\e[0m"
    else
      echo -e "\e[92mReset the branch\e[0m"
    fi
  fi

  display_prompt
}

#######################################
# Pop from the stash
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_restore {
  cd ${git_dir}

  local rc

  git stash pop
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] popping from the stash\e[0m"
  fi

  display_prompt
}

#######################################
# Revert a commit
# Globals:
#   git_dir
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_revert {
  cd ${git_dir}

  local commit
  local rc

  read -p 'commit to revert: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> ${history_file}

  if [ "$commit" = "menu" ]; then
    menu_commit
    commit="$menu_value"
  fi

  if [ -z "$commit" ]; then
    echo -e "\e[91mA commit number must be provided\e[0m"
  else
    git revert ${commit}

    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] reverting commit $commit\e[0m"
    else
      func_push
    fi
  fi

  display_prompt
}

#######################################
# Stash the current working files
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_save {
  cd ${git_dir}

  local rc

  git stash save
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] saving to the stash\e[0m"
  fi

  display_prompt
}

#######################################
# Set the default remote
# Globals:
#   git_dir
#   default_remote
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_server {
  cd ${git_dir}

  local remote

  read -p "remote name [${default_remote}]: " remote
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$remote\e[0m" >> ${history_file}
  default_remote=${remote:-$default_remote}
  echo -e "\e[92mchanged default remote to ${default_remote}\e[0m"

  display_prompt
}

#######################################
# Display current remotes
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_servers {
  cd ${git_dir}

  git remote -v

  display_prompt
}

#######################################
# Display current status
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_status {
  cd ${git_dir}

  git status -s

  display_prompt
}

#######################################
# Switch to a different branch
# Globals:
#   git_dir
#   default_branch
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_switch {
  cd ${git_dir}

  local branch

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  func_switch ${branch}

  display_prompt
}

#######################################
# Switch tracking of local branch to
#   different remote branch
# Globals:
#   git_dir
#   default_branch
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_track {
  cd ${git_dir}

  local server
  local branch

  read -p "remote [$default_remote]: " server
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$server\e[0m" >> ${history_file}
  server=${server:-$default_remote}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menu_value"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  func_switch ${branch}

  git branch -u ${server}/${branch}

  display_prompt
}

#######################################
# Soft reset the branch
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_undo {
  cd ${git_dir}

  local rc

  git reset --soft HEAD
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] with reset\e[0m"
  else
    echo -e "\e[92mRemoved the commit\e[0m"
  fi

  display_prompt
}

#######################################
# Remove remote tracking of a branch
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_untrack {
  cd ${git_dir}

  git branch --unset-upstream

  display_prompt
}

#######################################
# Pop from the stash
# Globals:
#   git_dir
#   default_remote
# Arguments:
#   Code branch
#   Server branch
# Returns:
#   None
#######################################
function func_merge {
  local branch_code
  local branch_server
  local rc

  script_comment "func_merge($1, $2)"
  branch_code="$1"
  branch_server="$2"

  git checkout ${branch_server}
  rc=$?
  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not switch to $branch_server\e[0m"
  else
    git merge ${branch_code}
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting branch merge\e[0m"
      echo -e "\e[93mPlease fix the conflicts and then push\e[0m"
    else
      func_push "${default_remote} $branch_server:$branch_server"
    fi
  fi
}

#######################################
# Pull from remote
# Globals:
#   git_dir
#   default_remote
#   pull_result
# Arguments:
#   None
# Returns:
#   None
#######################################
function func_pull {
  cd ${git_dir}

  local rc

  git pull --no-rebase -v ${default_remote}
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] with pull\e[0m"
  fi
  pull_result=${rc}
}

#######################################
# Push to remote
# Globals:
#   pull_result
# Arguments:
#   Remote server
# Returns:
#   None
#######################################
function func_push {
  local server
  local rc

  script_comment "func_push($1)"
  if [ -z "$1" ]; then
    server=''
  else
    server="$1"
  fi

  func_pull
  rc=${pull_result}
  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc]; aborting pull\e[0m"
    echo -e "\e[93mPlease fix the issue and then push\e[0m"
  else
    git push ${server}
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting push after pull\e[0m"
    fi
  fi
}

#######################################
# Switch branch and pull
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function func_switch {
  local branch
  local rc

  script_comment "func_switch($1)"
  branch="$1"

  git checkout ${branch}
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] checking out $branch\e[0m"
  else
    func_pull
  fi
}

#######################################
# Display a variable if it exists
# Globals:
#   git_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function func_var () {
  local variable

  read -p 'variable name: ' variable

  echo ${!variable}

  display_prompt
}

#######################################
# Strip spaces from branch name
# Globals:
#   menu_value
# Arguments:
#   Branch name
# Returns:
#   None
#######################################
function menu_adjust_branch () {
  local local_branch

  if [ -z "$1" ]; then
    return 1
  else
    local_branch="$1"

    # trim leading spaces from the branch name
    local_branch=`echo "$local_branch" | xargs`
  fi

  menu_value="${local_branch}"
}

#######################################
# Get the first 7 characters of the
#   commit hash
# Globals:
#   menu_value
# Arguments:
#   Commit hash
# Returns:
#   None
#######################################
function menu_adjust_commit () {
  local value

  if [ -z "$1" ]; then
    return 1
  else
    value="$1"
  fi

  menu_value="${value:0:7}"
}

#######################################
# Display a menu for branches
# Globals:
#   git_dir
#   prefix
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu_branch {
  cd ${git_dir}

  menu_display "git branch | egrep '${prefix}-' > $menu_file" 'branch number' 30 'menu_adjust_branch'
}

#######################################
# Display a menu for commits
# Globals:
#   git_dir
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu_commit {
  cd ${git_dir}

  menu_display "git log --oneline --decorate -10 > $menu_file" 'commit number' 10 'menu_adjust_commit'
}

#######################################
# Display a menu with a prompt for a
#   menu item number
# Globals:
#   git_dir
#   menu_temp
#   menu_file
#   stamp
#   history_file
# Arguments:
#   Command
#   Menu Prompt
#   Item Numbers
#   Menu Function
# Returns:
#   None
#######################################
function menu_display () {
  cd ${git_dir}

  local command
  local menu_prompt
  local item_numbers
  local menu_function
  local i
  local line
  local menu_item
  local value
  local rc

  # validate arguments
  if [ -z "$1" ]; then
    echo -e "\e[91mmenu_display was called without a command parameter"
    return 1
  else
    command="$1"
  fi

  if [ -z "$2" ]; then
    echo -e "\e[91mmenu_display was called without a prompt parameter"
    return 2
  else
    menu_prompt="$2"
  fi

  if [ -z "$3" ]; then
    echo -e "\e[91mmenu_display was called without a number of items parameter"
    return 3
  else
    item_numbers="$3"
  fi

  if [ -z "$4" ]; then
    echo -e "\e[91mmenu_display was called without a value manipulation function parameter"
    return 4
  else
    menu_function="$4"
  fi

  # execute the command and write the contents to the menuFile
  eval "${command}"

  # prepare lines for menu usage
  menu_temp=`cat ${menu_file}`

  # loop through file to display items and their corresponding index in menuTemp
  i=0
  while read line; do
    if [ ${i} -eq ${item_numbers} ]; then
      break
    fi
    i=$[$i+1]
    printf "%2s: %s\n" "$i" "$line"
  done < "$menu_file"

  read -p "${menu_prompt}: " menu_item
  if [ -n "$menu_item" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$menu_item\e[0m" >> ${history_file}
  fi

  # give the user 3 chances to enter something valid
  i=0
  while [ -z ${menu_item} ]; do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a number of a ${menuPrompt} menu item: \e[0m' menu_item
    if [ -n "$menu_item" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$menu_item\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${menu_item} ]; then
    echo -e "\e[91mA ${menu_prompt} menu item number must be specified\e[0m"
  else
    # get the value from the file at the specified line
    value=$(sed "${menu_item}q;d" ${menu_file})
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] with sed.\e[0m"
    else
      # check for current branch (denoted by "* " before the branch name)
      first=$(echo "${value}" | cut -d' ' -f 1)
      if [ "$first" = "*" ]; then
        value="${value:2}"
      fi

      # execute function with this value
      eval ${menu_function} "${value}"

      echo "using value $menu_value"
    fi
  fi
}

#######################################
# Display a comment to the user
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_comment {
  echo -e "\e[100m${1}\e[0m"
}

#######################################
# Set the git directory
# Globals:
#   git_dir
#   in_git
#   original_git_dir
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_dir {
  local i

  read -e -p "Please specify the git directory[${git_dir}]: " git_dir

  i="0"
  while [ ! -d "$git_dir" ]; do
    if [ ${i} -eq 5 ]; then
      echo -e "\e[91mPlease specify the correct git directory and try again.\e[0m"
      break
    fi
    i=$[$i+1]

    read -e -p 'Please specify the git directory: ' git_dir
  done

  # check for git directory
  script_in_git_dir
  if [ "$in_git" != 'true' ]; then
    echo -e "\e[91mCurrent git directory [${git_dir}] is not a valid working tree\e[0m"
    git_dir="$original_git_dir"
  else
    history_file="$PWD/.mtsgit_history"
  fi

  display_prompt
}

#######################################
# Display history from this program
# Globals:
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_history {
  less +G -r -N ${history_file}

  display_prompt
}

#######################################
# Test for being in a working tree
# Globals:
#   git_dir
#   in_git
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_in_git_dir {
  cd ${git_dir}

  local rc

  in_git=$(git rev-parse --is-inside-work-tree)
  rc=$?

  if [ ${rc} -gt 0 ]; then
    in_git='false'
  fi
}

#######################################
# Obtain the prefix of the branch as
#   the characters before the first
#   hyphen
# Globals:
#   default_branch
#   prefix
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_prefix {
  local temp_array=()

  temp_array=(${default_branch//-/ })
  prefix="${temp_array[0]}"
}

#######################################
# Set the default branch
# Globals:
#   current_branch
#   default_branch
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_set {
  read -p "default branch [${current_branch}]: " default_branch
  default_branch=${default_branch:-$current_branch}

  echo -e "\e[92mSet default branch to \e[32m${default_branch}"

  script_prefix

  display_prompt
}

#######################################
# Set the current branch to the default
#   branch and set the prefix
# Globals:
#   default_branch
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_set_current {
  set_current
  default_branch="$current_branch"
  script_prefix
}

#######################################
# Set the default truth
# Globals:
#   stamp
#   history_file
#   default_truth
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_truth {
  local truth
  local i
  local lines

  read -p "default source of truth branch: " truth
  if [ -n "$truth" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${truth} ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify the source of truth: \e[0m' truth
    if [ -n "$truth" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${truth} ]; then
    echo -e "\e[91mNo branch specified"
  else
    cd ${git_dir}

    # check to see if the $truth branch actually exists before setting default
    lines=$(eval "git branch | egrep '^\**\s*${truth}$' | wc -l")
    if [ "$lines" = "1" ]; then
      default_truth="$truth"
      echo -e "\e[92mSet default source of truth to \e[96m${default_truth}"
    else
      echo -e "\e[91mBranch $truth does not exist"
    fi
  fi

  display_prompt
}

#######################################
# Display variables of this script
# Globals:
#   git_dir
#   prompt
#   default_branch
#   default_truth
#   current_branch
#   default_prod_server
#   default_remote
#   prefix
#   history_file
#   version
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_variables {
  echo -e "\e[0mCurrent Variables"
  echo
  echo -e "git_dir: \e[33m$git_dir\e[0m"
  echo -e "prompt: \e[95m$prompt\e[0m"
  echo -e "default_branch: \e[32m$default_branch\e[0m"
  echo -e "default_truth: \e[96m$default_truth\e[0m"
  echo -e "current_branch: \e[36m$current_branch\e[0m"
  echo -e "default_prod_server: $default_prod_server\e[0m"
  echo -e "default_remote: $default_remote\e[0m"
  echo -e "prefix: \e[35m$prefix\e[0m"
  echo -e "history_file: $history_file\e[0m"
  echo -e "version: \e[94m$version\e[0m"

  display_prompt
}

#######################################
# Set the current branch to the working
#   directory head
# Globals:
#   current_branch
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_current {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
}

#######################################
# Set the date time stamp
# Globals:
#   stamp
# Arguments:
#   None
# Returns:
#   None
#######################################
function datetimestamp {
  stamp=`date +%Y-%m-%d_%H:%M:%S`
}

#######################################
# Clean up files and exit cleanly
# Globals:
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function quit {
  rm -f ${menu_file}
  echo 'Thank you for using MTSgit'
  exit 0
}

# Script Variables
current_branch=''
default_branch=''
in_git=''
original_git_dir="$git_dir"
prefix=''
prompt='MTSgit'
pull_result=99
stamp=''
version='1.39'

# check for directory existence
if [ ! -d "$git_dir" ]; then
  script_dir
  if [ ! -d "$git_dir" ]; then
    echo -e "\e[91mUnable to find directory $git_dir.\e[0m"
    sleep 3
    exit 1
  fi
fi

# check for git directory
script_in_git_dir
if [ "$in_git" != 'true' ]; then
  echo -e "\e[91mCurrent git directory [${git_dir}] is not a valid working tree\e[0m"
  sleep 5
  exit 2
fi

# set directory for history file location
cd ${git_dir}
cd ..

history_file="$PWD/.mtsgit_history"
menu_temp=''
menu_file="$PWD/mtstemp_menu"
menu_value=''

cd ${git_dir}

echo 'MTSgit: An interactive script for standard git commands'
echo -e "Version \e[94m${version}\e[0m"
echo '                    by Mike Rodarte'
echo
echo 'Type help for a list of available commands.'
echo 'Press <Enter> to execute the command.'
echo 'To set up for a non-default repository, execute dir and truth.'
echo

script_set_current
display_prompt
