#!/bin/bash
# Author: Mike Rodarte
#
# Interactive script for git shortcuts and scripts

if [ -e ~/.bashrc ]; then
  . ~/.bashrc
fi

# Variables BEGIN
# User Variables
use_dir=${git_dir:-'/var/www/html'}
default_truth='master'
default_prod_server='production'
default_remote='origin'
directories=("${git_dir}" "${gitDir}" "${PWD}")
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
  read -p $'\x1B[95m'"${prompt}"$'\x1B[36m'" ${current_branch}"$'\x1B[95m'"> "$'\x1B[0m' choice
  datetimestamp
  echo -e "\x1B[35m${stamp}\x1B[0m ${choice}\x1B[0m" >> ${history_file}
  case "${choice}" in
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
    *) echo -e "\x1B[91mUnknown command ${choice}\x1B[0m";show_commands;;
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
#   use_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_add {
  cd ${use_dir}

  local files
  local i
  local cmd
  local rc
  
  read -e -p 'file name: ' files
  if [ -n "${files}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${files}\x1B[0m" >> ${history_file}
  fi

  i="0"
  while [ -z "${files}" ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    # show result of "git status" to help indicate what should be added
    if [ ${i} -eq 1 ]; then
      cmd='git status -s'
      eval ${cmd}
      log_git "${cmd}"
    fi
    read -e -p $'\x1B[91mPlease specify a file name: \x1B[0m' files
    if [ -n "${files}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${files}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${files}" ]; then
    echo -e "\x1B[91mA file name was not specified\x1B[0m"
  else
    cmd="git add ${files}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] with add\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Display changes between truth and
#   branch or commit
# Globals:
#   use_dir
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
  cd ${use_dir}

  local changed
  local truth
  local cmd
  local rc

  read -p "branch or commit name [${default_branch}]: " changed
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${changed}\x1B[0m" >> ${history_file}
  changed=${changed:-$default_branch}

  if [ "${changed}" = "menu" ]; then
    menu_branch
    changed="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    changed=${changed:-$default_branch}
  fi

  read -p "source of truth name [${default_truth}]: " truth
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${truth}\x1B[0m" >> ${history_file}
  truth=${truth:-$default_truth}

  cmd="git diff --name-only ${changed} ${truth}"
  eval ${cmd}
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] with diff\x1B[0m"
  fi

  display_prompt
}

#######################################
# Clone a repository
# Globals:
#   use_dir
# Arguments:
#   Repository string (user@host:repo)
#   Directory (optional)
# Returns:
#   None
#######################################
function git_clone () {
  if [ -z "${1}" ]; then
    echo -e "\x1B[91mPlease provide user@host:repository.git\x1B[0m"
    return 1
  fi

  local rc
  local answer

  # parameter 2 is the directory to use
  local directory=''
  if [ -n "{$2}" ]; then
    if [ -d "${2}" ]; then
      echo -e "\x1B[91mError: directory ${2} already exists\x1B[0m"
      return 2
    fi
    directory="${2}"
  fi

  # verify the current directory is not a git directory
  git rev-parse --is-inside-work-tree > /dev/null 2>&1
  rc=$?

  # if return code is 0, this is a git directory
  if [ "${rc}" -eq 0 ]; then
    # prompt user because cloning a repository into another repository might be bad
    read -p 'Are you sure you want to clone the repository into an existing repository? [y/N] ' answer
    if [ "${answer}" != 'y' ]; then
      return 4
    fi
  fi

  # do the clone
  git clone ${1} ${directory}
  rc=$?

  if [ "${rc}" -gt 0 ]; then
    echo -e "\x1B[91mError ${rc} with git clone for ${1}\x1B[0m"
    return 8
  fi

  # get directory name if it doesn't exist
  if [ -z "${directory}" ]; then
    # pull name from between : and .git in $1
    directory=$(echo "${1}" | sed -E 's/.+:([a-zA-Z0-9_-]+)\.git/\1/')
  fi

  cd ${directory}
  # add this directory to the list of directories
  directories+=("${PWD}")
  use_dir="${PWD}"
}

#######################################
# Commit files to git
# Globals:
#   use_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_commit {
  cd ${use_dir}

  local message
  local i
  local cmd
  local rc

  read -p "message: " message
  if [ -n "${message}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${message}\x1B[0m" >> ${history_file}
  fi

  i="0"
  while [ -z "${message}" ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\x1B[91mPlease specify a commit message: \x1B[0m' message
    if [ -n "${message}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${message}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${message}" ]; then
    echo -e "\x1B[91mPlease commit with a message\x1B[0m"
  else
    cmd="git commit -a -m \"${message}\""
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] with commit\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Create a new branch
# Globals:
#   use_dir
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
  cd ${use_dir}

  local remote
  local branch
  local cmd
  local rc

  read -p 'from remote? [y|n] ' remote
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${remote}\x1B[0m" >> ${history_file}

  read -p "new branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  func_switch ${default_truth}
  rc=${pull_result}
  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] with checking out ${default_truth}\x1B[0m"
  else
    if [ "y" = "${remote}" ]; then
      cmd="git checkout --track ${default_remote}/${branch}"
    else
      cmd="git checkout -b ${branch}"
    fi
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}]; failed to create branch\x1B[0m"
    else
      echo -e "\x1B[92mCreated ${branch}\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Set and display the current branch
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_current {
  cd ${use_dir}

  set_current
  echo -e "\x1B[36m${current_branch}\x1B[0m"

  display_prompt
}

#######################################
# Delete a branch
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch
  local to_delete
  local answer
  local cmd
  local rc

  cmd="git checkout ${default_truth}"
  eval ${cmd}
  log_git "${cmd}"

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  to_delete=1
  if [ "${branch}" = ${default_truth} ]; then
    echo -e "\x1B[101mDeleting the default truth branch is not recommended."
    read -p "Are you sure you want to delete the source of truth? [y/n]: " answer
    if [ "${answer}" = "y" ]; then
      to_delete=1
    elif [ "${answer}" = "n" ]; then
      to_delete=0
    else
      to_delete=0
      echo -e "\x1B[91mUnknown answer ${answer}\x1B[0m"
    fi
  fi

  if [ ${to_delete} -eq 1 ]; then
    cmd="git branch -D ${branch}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}]; could not delete branch ${branch}\x1B[0m"
    fi
  else
    echo -e "\x1B[93mSkipping deletion of ${branch}\x1B[0m"
  fi

  display_prompt
}

#######################################
# Deploy code to default remote and
#   default production remote
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch_code
  local branch_server
  local i
  local command
  local cmd
  local default_deploy
  local deploy_server

  read -p "code branch name [${default_branch}]: " branch_code
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch_code}\x1B[0m" >> ${history_file}
  branch_code=${branch_code:-$default_branch}

  if [ "${branch_code}" = "menu" ]; then
    menu_branch
    branch_code="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch_code=${branch_code:-$default_branch}
  fi

  read -p "server branch name: " branch_server
  if [ -n "${branch_server}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${branch_server}\x1B[0m" >> ${history_file}
  fi

  i="0"
  while [ -z "${branch_server}" ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    if [ ${i} -eq 1 ] && [ ! -z "${prefix}" ]; then
      echo -e "\x1B[93mDid you mean one of these branches?\x1B[0m"
      # suggest a branch name
      command="git branch -r | egrep '${prefix}-[A-Z]+[0-9]*\b$'"
      eval ${command}
      log_git "${command}"
    fi
    read -p $'\x1B[91mPlease specify a server branch name: \x1B[0m' branch_server
    if [ -n "${branch_server}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${branch_server}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${branch_server}" ]; then
    echo -e "\x1B[91mError: A branch name must be provided\x1B[0m"
  else
    default_deploy="${default_prod_server}/${default_truth}"
    read -p "deployment server branch name [${default_deploy}]: " deploy_server
    deploy_server=${deploy_server:-$default_deploy}

    script_comment "Switching to ${branch_server}"
    cmd="git checkout ${branch_server}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Merging ${branch_code} to ${branch_server}"
    cmd="git merge ${branch_code}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Pushing ${default_truth} to ${branch_server}"
    cmd="git push ${default_remote} ${default_truth}:${default_truth}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Switching to ${deploy_server}"
    cmd="git checkout ${deploy_server}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Merging ${branch_code} to ${deploy_server}"
    cmd="git merge ${branch_code}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Pushing ${default_truth} to ${deploy_server}"
    cmd="git push ${default_prod_server} ${default_truth}:${default_truth}"
    eval ${cmd}
    log_git "${cmd}"
    script_comment "Switching to ${branch_server}"
    cmd="git checkout ${branch_server}"
    eval ${cmd}
    log_git "${cmd}"
  fi

  display_prompt
}

#######################################
# Set the default deployment remote
# Globals:
#   use_dir
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
  cd ${use_dir}

  local deploy_server
  local git_path
  local cmd
  local rc

  read -p "deployment server branch name [${default_prod_server}]: " deploy_server
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${deploy_server}\x1B[0m" >> ${history_file}
  deploy_server=${deploy_server:-$default_deploy}

  read -p "git path (include ssh://user@host:port/path): " git_path
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${deploy_server}\x1B[0m" >> ${history_file}
  if [ -z "${git_path}" ]; then
    echo -e "\x1B[91mError: A git path must be added\x1B[0m"
  else
    cmd="git remote add ${deploy_server} ${git_path}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] adding remote branch\x1B[0m"
    else
      cmd="git push ${deploy_server} +${default_truth}:refs/heads/${default_truth}"
      eval ${cmd}
      rc=$?
      log_git "${cmd}"

      if [ ${rc} -gt 0 ]; then
        echo -e "\x1B[91mError pushing to deployment server\x1B[0m"
      fi
    fi
  fi

  display_prompt
}

#######################################
# Make a file executable
# Globals:
#   use_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_exec {
  cd ${use_dir}

  local file
  local cmd

  read -e -p 'file to make executable: ' file
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${file}\x1B[0m" >> ${history_file}

  if [ -e "${file}" ]; then
    cmd="git update-index --chmod=+x ${file}"
    eval ${cmd}
    log_git "${cmd}"
  else
    echo -e "\x1B[91mError: file ${file} does not exist\x1B[0m"
  fi

  display_prompt
}

#######################################
# List local or remote branches
# Globals:
#   use_dir
#   stamp
#   history_file
#   default_truth
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_list {
  cd ${use_dir}

  local remote
  local command
  local filter
  local cmd
  local rc

  read -p 'remote [y/n]: ' remote
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${remote}\x1B[0m" >> ${history_file}

  command='git branch'

  read -p "filter: " filter
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${filter}\x1B[0m" >> ${history_file}

  if [ "${remote}" = "y" ]; then
    command="${command} -r"

    # check for new branches that were pushed since the last pull
    echo -e "\x1B[36mChecking for remote branches...\x1B[0m"
    echo
    cmd="git checkout ${default_truth}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] checking out ${default_truth}\x1B[0m"
    else
      func_pull
    fi
    echo
    echo -e "\x1B[33mRemote Branches\x1B[0m"
  elif [ "${remote}" != "n" ]; then
    echo -e "\x1B[91mInvalid response\x1B[0m"
  else
    echo
    echo -e "\x1B[33mLocal Branches\x1B[0m"
  fi

  if [ ! -z "${filter}" ]; then
    command="${command} | grep ${filter}"
  fi

  eval ${command}
  rc=$?
  log_git "{${command}}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}]; could not list branches\x1B[0m"
  fi

  display_prompt
}

#######################################
# Show log for branch with author,
#   file, and days ago options
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch
  local author
  local file
  local default_days
  local days
  local days_ago
  local file_cmd
  local cmd
  local rc

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  read -p "author (blank for all): " author
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${author}\x1B[0m" >> ${history_file}

  read -e -p "file relative to repo root (blank for all): " file
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${file}\x1B[0m" >> ${history_file}

  default_days=7
  read -p "days ago [${default_days}]: " days
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${days}\x1B[0m" >> ${history_file}

  if [ "${days}" -eq "${days}" ] > /dev/null 2>&1
  then
    days=${days}
  else
    days=${default_days}
  fi
  days_ago=$(date --date="${days} days ago" +"%Y"-"%m"-"%d")

  cmd="git checkout ${branch}"
  eval ${cmd}
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}]; could not checkout ${branch}\x1B[0m"
  else
    file_cmd=''
    if [ -n "${file}" ]; then
      file_cmd=" --follow -p ${file}"
    fi
    cmd="git log --stat --graph --author=${author} --since=\"${days_ago}\" ${file_cmd}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}]; could not get log\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Merge two branches
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch_code
  local branch_server
  local i
  local command

  read -p "code branch name [${default_branch}]: " branch_code
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch_code}\x1B[0m" >> ${history_file}
  branch_code=${branch_code:-$default_branch}

  if [ "${branch_code}" = "menu" ]; then
    menu_branch
    branch_code="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch_code=${branch_code:-${default_branch}}
  fi

  read -p "server branch name: " branch_server
  if [ -n "${branch_server}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${branch_server}\x1B[0m" >> ${history_file}
  fi

  i="0"
  while [ -z "${branch_server}" ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    if [ ${i} -eq 1 ] && [ ! -z "${prefix}" ]; then
      echo -e "\x1B[93mDid you mean one of these branches?\x1B[0m"
      # suggest a branch name
      command="git branch -r | egrep '${prefix}-[A-Z]+[0-9]*\b$'"
      eval ${command}
      log_git "${command}"
    fi
    read -p $'\x1B[91mPlease specify a server branch name: \x1B[0m' branch_server
    if [ -n "${branch_server}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${branch_server}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${branch_server}" ]; then
    echo -e "\x1B[91mA server branch name must be specified\x1B[0m"
  else
    func_merge ${branch_code} ${branch_server}
  fi

  display_prompt
}

#######################################
# Update the message for the latest
#   commit
# Globals:
#   use_dir
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_message {
  cd ${use_dir}

  local message
  local cmd
  local rc

  read -p 'new commit message: ' message
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${message}\x1B[0m" >> ${history_file}

  if [ -n "${message}" ]; then
    cmd="git commit --amend -m \"${message}\""
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError amending the commit message\x1B[0m"
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
#   use_dir
#   default_remote
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_push {
  cd ${use_dir}

  local default_server
  local server

  default_server=${default_remote}
  read -p "server [${default_server}]: " server
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${server}\x1B[0m" >> ${history_file}
  server=${server:-$default_server}

  func_push ${server}

  display_prompt
}

#######################################
# Push a branch to a remote
# Globals:
#   use_dir
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
  cd ${use_dir}

  local default_server
  local server
  local branch
  local cmd
  local rc

  default_server=${default_remote}
  read -p "server [${default_server}]: " server
  server=${server:-$default_server}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ -z "${branch}" ]; then
    echo -e "\x1B[91Please enter a branch name\x1B[0m"
  else
    cmd="git push -u ${default_server} ${branch}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] making branch ${branch} remote\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Hard reset a branch to a commit
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch
  local cmd
  local rc
  local commit
  local answer

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ "${branch}" != "${current_branch}" ]; then
    cmd="git checkout ${branch}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] checking out ${branch}\x1B[0m"
      echo "using ${current_branch} instead of ${branch}"
      branch="${current_branch}"
    fi
    script_set_current
  fi

  read -p 'commit name: ' commit
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${commit}\x1B[0m" >> ${history_file}

  if [ "${commit}" = "menu" ]; then
    menu_commit
    commit="${menu_value}"
  fi

  read -p "Are you sure you want to reset ${branch}? [y/n] " answer
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${answer}\x1B[0m" >> ${history_file}

  if [ "${answer}" = 'y' ]; then
    cmd="git reset --hard ${commit}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] with reset\x1B[0m"
    else
      echo -e "\x1B[92mReset the branch\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Pop from the stash
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_restore {
  cd ${use_dir}

  local cmd
  local rc

  cmd='git stash pop'
  eval ${cmd}
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] popping from the stash\x1B[0m"
  fi

  display_prompt
}

#######################################
# Revert a commit
# Globals:
#   use_dir
#   stamp
#   history_file
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_revert {
  cd ${use_dir}

  local commit
  local cmd
  local rc

  read -p 'commit to revert: ' commit
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${commit}\x1B[0m" >> ${history_file}

  if [ "${commit}" = "menu" ]; then
    menu_commit
    commit="${menu_value}"
  fi

  if [ -z "${commit}" ]; then
    echo -e "\x1B[91mA commit number must be provided\x1B[0m"
  else
    cmd="git revert ${commit}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] reverting commit ${commit}\x1B[0m"
    else
      func_push
    fi
  fi

  display_prompt
}

#######################################
# Stash the current working files
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_save {
  cd ${use_dir}

  local cmd
  local rc

  cmd='git stash save'
  eval "${cmd}"
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] saving to the stash\x1B[0m"
  fi

  display_prompt
}

#######################################
# Set the default remote
# Globals:
#   use_dir
#   default_remote
#   stamp
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_server {
  cd ${use_dir}

  local remote

  read -p "remote name [${default_remote}]: " remote
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${remote}\x1B[0m" >> ${history_file}
  default_remote=${remote:-$default_remote}
  echo -e "\x1B[92mchanged default remote to ${default_remote}\x1B[0m"

  display_prompt
}

#######################################
# Display current remotes
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_servers {
  cd ${use_dir}

  local cmd

  cmd='git remote -v'
  eval ${cmd}
  log_git "${cmd}"

  display_prompt
}

#######################################
# Display current status
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_status {
  cd ${use_dir}

  local cmd

  cmd='git status -s'
  eval ${cmd}
  log_git "${cmd}"

  display_prompt
}

#######################################
# Switch to a different branch
# Globals:
#   use_dir
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
  cd ${use_dir}

  local branch

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

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
#   use_dir
#   default_branch
#   menu_value
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_track {
  cd ${use_dir}

  local server
  local branch
  local cmd

  read -p "remote [${default_remote}]: " server
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${server}\x1B[0m" >> ${history_file}
  server=${server:-$default_remote}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\x1B[35m${stamp}   \x1B[33m${branch}\x1B[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "${branch}" = "menu" ]; then
    menu_branch
    branch="${menu_value}"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  func_switch ${branch}

  if [ ${pull_result} -eq 0 ]; then
    cmd="git branch -u ${server}/${branch}"
    eval ${cmd}
    log_git "${cmd}"
  fi

  display_prompt
}

#######################################
# Soft reset the branch
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_undo {
  cd ${use_dir}

  local cmd
  local rc

  cmd='git reset --soft HEAD'
  eval ${cmd}
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] with reset\x1B[0m"
  else
    echo -e "\x1B[92mRemoved the commit\x1B[0m"
  fi

  display_prompt
}

#######################################
# Remove remote tracking of a branch
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function git_untrack {
  cd ${use_dir}

  local cmd='git branch --unset-upstream'
  eval ${cmd}
  log_git "${cmd}"

  display_prompt
}

#######################################
# Prompt for git directory
# Globals:
#   use_dir
# Arguments:
#   None
# Returns:
#   None
#######################################
function func_dir {
  local i="0"

  read -e -p "Please specify the git directory[${use_dir}]: " use_dir

  if [ "${use_dir}" = 'menu' ]; then
    menu_directory
  fi

  if [ "${menu_value}" = 'Other' ] || [ "${use_dir}" != 'menu' ] || [ -z "${menu_value}" ]; then
    while [ ! -d "${use_dir}" ]; do
      if [ ${i} -eq 5 ]; then
        echo -e "\x1B[91mPlease specify the correct git directory.\x1B[0m"
        break
      fi
      i=$[$i+1]

      read -e -p 'Please specify the git directory: ' use_dir
    done
  else
    use_dir="${menu_value}"
  fi

  if [ -z "${use_dir}" ] || [ ! -d "${use_dir}" ]; then
    echo -e "\x1B[91mNo git directory is set\x1B[0m"
  else
    # check for git directory
    script_in_git_dir
    if [ "${in_git}" != 'true' ]; then
      echo -e "\x1B[91mCurrent git directory [${use_dir}] is not a valid working tree\x1B[0m"
      use_dir="${original_git_dir}"
    else
      history_file="${PWD}/.mtsgit_history"

      # check for use_dir in directories
      exists=0
      for dir in ${directories[@]}; do
        if [ "${dir}" = "${use_dir}" ]; then
          exists=1
          break
        fi
      done

      # append this directory to directories if it does not exist
      if [ "${exists}" -eq 0 ]; then
        directories+=("${use_dir}")
      fi
    fi
  fi
}

#######################################
# Pop from the stash
# Globals:
#   use_dir
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
  local cmd
  local rc

  script_comment "func_merge(${1}, ${2})"
  branch_code="${1}"
  branch_server="${2}"

  func_switch ${default_truth}
  if [ ${pull_result} -gt 0 ]; then
    echo -e "\x1B[91mError [${pull_result}]; could not switch to ${default_truth}\x1B[0m";
  else
    func_switch ${branch_server}
    if [ ${pull_result} -gt 0 ]; then
      echo -e "\x1B[91mError [${pull_result}]; could not switch to ${branch_server}\x1B[0m"
    else
      cmd="git merge ${branch_code}"
      eval ${cmd}
      rc=$?
      log_git "${cmd}"

      if [ ${rc} -gt 0 ]; then
        echo -e "\x1B[91mError [${rc}]; aborting branch merge\x1B[0m"
        echo -e "\x1B[93mPlease fix the conflicts and then push\x1B[0m"
      else
        if [ "${is_remote}" -eq 1 ]; then
          func_push "${default_remote} ${branch_server}:${branch_server}"
        fi
      fi
    fi
  fi
}

#######################################
# Pull from remote
# Globals:
#   use_dir
#   default_remote
#   is_remote
#   current_branch
#   pull_result
# Arguments:
#   None
# Returns:
#   None
#######################################
function func_pull {
  cd ${use_dir}

  local cmd
  local rc

  set_current

  if [ ${is_remote} -eq 1 ]; then
    cmd='git pull'
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] with pull\x1B[0m"
    fi
    pull_result=${rc}
  else
    # be sure to let the caller know this was successful
    pull_result=0
  fi
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
  local cmd
  local rc

  script_comment "func_push(${1})"
  if [ -z "${1}" ]; then
    server=''
  else
    server="${1}"
  fi

  func_pull
  if [ ${pull_result} -gt 0 ]; then
    echo -e "\x1B[91mError [${pull_result}]; aborting pull\x1B[0m"
    echo -e "\x1B[93mPlease fix the issue and then push\x1B[0m"
    return ${pull_result}
  else
    cmd="git push ${server}"
    eval ${cmd}
    rc=$?
    log_git "${cmd}"

    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}]; aborting push after pull\x1B[0m"
      return ${rc}
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
  local cmd
  local rc

  script_comment "func_switch(${1})"
  branch="${1}"

  # if the branch is empty, there is nothing to do
  if [ -z "${branch}" ]; then
    echo -e "\x1B[91mA branch name must be specified in order to checkout a branch\x1B[0m"
    return 1
  fi

  cmd="git checkout ${branch}"
  eval ${cmd}
  rc=$?
  log_git "${cmd}"

  if [ ${rc} -gt 0 ]; then
    echo -e "\x1B[91mError [${rc}] checking out ${branch}\x1B[0m"
    pull_result=${rc}
  else
    func_pull
  fi
}

#######################################
# Display a variable if it exists
# Globals:
#   use_dir
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

  if [ -z "${1}" ]; then
    return 1
  else
    local_branch="${1}"

    # trim leading spaces from the branch name
    local_branch=`echo "${local_branch}" | xargs`
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

  if [ -z "${1}" ]; then
    return 1
  else
    value="${1}"
  fi

  menu_value="${value:0:7}"
}

#######################################
# Set directory to chosen value
# Globals:
#   menu_value
# Arguments:
#   Directory name
# Returns:
#   None
#######################################
function menu_adjust_directory () {
  if [ -z "${1}" ]; then
    return 1
  else
    menu_value="${1}"
  fi
}

#######################################
# Display a menu for branches
# Globals:
#   use_dir
#   prefix
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu_branch {
  cd ${use_dir}

  menu_display "git branch | egrep '${prefix}-' > ${menu_file}" 'branch number' 30 'menu_adjust_branch'
}

#######################################
# Display a menu for commits
# Globals:
#   use_dir
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu_commit {
  cd ${use_dir}

  menu_display "git log --oneline --decorate -10 > ${menu_file}" 'commit number' 10 'menu_adjust_commit'
}

#######################################
# Display a menu for git directories
# Globals:
#   directories
#   menu_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function menu_directory {
  if [ -f "${menu_file}" ]; then
    # clear the menu_file since the command will append to it
    rm ${menu_file}
  fi
  touch ${menu_file}
  for dir in "${directories[@]}"; do
    if [ -d "${dir}" ]; then
      echo "${dir}" >> ${menu_file}
    fi
  done
  echo Other >> ${menu_file}
  menu_display "touch ${menu_file}" 'directory number' 5 'menu_adjust_directory'
}

#######################################
# Display a menu with a prompt for a
#   menu item number
# Globals:
#   use_dir
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
#   Int
#######################################
function menu_display () {
  if [ -d "${use_dir}" ]; then
    cd ${use_dir}
  fi

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
  if [ -z "${1}" ]; then
    echo -e "\x1B[91mmenu_display was called without a command parameter\x1B[0m"
    return 1
  else
    command="${1}"
  fi

  if [ -z "${2}" ]; then
    echo -e "\x1B[91mmenu_display was called without a prompt parameter\x1B[0m"
    echo "${1}"
    return 2
  else
    menu_prompt="${2}"
  fi

  if [ -z "${3}" ]; then
    echo -e "\x1B[91mmenu_display was called without a number of items parameter\x1B[0m"
    return 3
  else
    item_numbers="${3}"
  fi

  if [ -z "${4}" ]; then
    echo -e "\x1B[91mmenu_display was called without a callback function parameter\x1B[0m"
    return 4
  else
    menu_function="${4}"
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
    printf "%2s: %s\n" "${i}" "${line}"
  done < "${menu_file}"

  read -p "${menu_prompt}: " menu_item
  if [ -n "${menu_item}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${menu_item}\x1B[0m" >> ${history_file}
  fi

  # give the user 3 chances to enter something valid
  i=0
  while [ -z "${menu_item}" ]; do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\x1B[91mPlease specify a number of a ${menuPrompt} menu item: \x1B[0m' menu_item
    if [ -n "${menu_item}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${menu_item}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${menu_item}" ]; then
    echo -e "\x1B[91mA ${menu_prompt} menu item number must be specified\x1B[0m"
  else
    # get the value from the file at the specified line
    value=$(sed "${menu_item}q;d" ${menu_file})
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\x1B[91mError [${rc}] with sed.\x1B[0m"
    else
      # check for current branch (denoted by "* " before the branch name)
      first=$(echo "${value}" | cut -d' ' -f 1)
      if [ "${first}" = "*" ]; then
        value="${value:2}"
      fi

      # execute function with this value
      eval ${menu_function} "${value}"

      echo "using value ${menu_value}"
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
  echo -e "\x1B[100m${1}\x1B[0m"
}

#######################################
# Set the git directory
# Globals:
#   use_dir
#   in_git
#   original_git_dir
#   history_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_dir {
  func_dir

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
#   use_dir
#   in_git
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_in_git_dir {
  cd ${use_dir}

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

  echo -e "\x1B[92mSet default branch to \x1B[32m${default_branch}\x1B[0m"

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
  default_branch="${current_branch}"
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
  if [ -n "${truth}" ]; then
    datetimestamp
    echo -e "\x1B[35m${stamp}   \x1B[33m${truth}\x1B[0m" >> ${history_file}
  fi

  i="0"
  while [ -z "${truth}" ]
  do
    if [ ${i} -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\x1B[91mPlease specify the source of truth: \x1B[0m' truth
    if [ -n "${truth}" ]; then
      datetimestamp
      echo -e "\x1B[35m${stamp}   \x1B[33m${truth}\x1B[0m" >> ${history_file}
    fi
  done

  if [ -z "${truth}" ]; then
    echo -e "\x1B[91mNo branch specified"
  else
    cd ${use_dir}

    # check to see if the $truth branch actually exists before setting default
    lines=$(eval "git branch | egrep '^\**\s*${truth}$' | wc -l")
    if [ "${lines}" = "1" ]; then
      default_truth="${truth}"
      echo -e "\x1B[92mSet default source of truth to \x1B[96m${default_truth}\x1B[0m"
    else
      echo -e "\x1B[91mBranch ${truth} does not exist\x1B[0m"
    fi
  fi

  display_prompt
}

#######################################
# Display variables of this script
# Globals:
#   use_dir
#   prompt
#   default_branch
#   default_truth
#   current_branch
#   default_prod_server
#   default_remote
#   is_local
#   is_remote
#   prefix
#   history_file
#   version
# Arguments:
#   None
# Returns:
#   None
#######################################
function script_variables {
  echo -e "\x1B[0mCurrent Variables"
  echo
  echo -e "use_dir: \x1B[33m${use_dir}\x1B[0m"
  echo -e "prompt: \x1B[95m${prompt}\x1B[0m"
  echo -e "default_branch: \x1B[32m${default_branch}\x1B[0m"
  echo -e "default_truth: \x1B[96m${default_truth}\x1B[0m"
  echo -e "current_branch: \x1B[36m${current_branch}\x1B[0m"
  echo -e "default_prod_server: ${default_prod_server}\x1B[0m"
  echo -e "default_remote: ${default_remote}\x1B[0m"
  echo -e "is_local: ${is_local}\x1B[0m"
  echo -e "is_remote: ${is_remote}\x1B[0m"
  echo -e "prefix: \x1B[35m${prefix}\x1B[0m"
  echo -e "history_file: ${history_file}\x1B[0m"
  echo -e "version: \x1B[94m${version}\x1B[0m"

  display_prompt
}

#######################################
# Set the current branch to the working
#   directory head and set is_local and
#   is_remote variables
# Globals:
#   current_branch
#   default_remote
#   is_local
#   is_remote
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_current {
  current_branch=$(git rev-parse --abbrev-ref HEAD)

  # reset the global variables
  is_local=0
  is_remote=0

  local local_result
  local local_response
  local remote_result
  local remote_response

  local_result=$(git show-ref --quiet --verify -- "refs/heads/${current_branch}" || echo "false")
  local_response=$?
  remote_result=$(git show-ref --quiet --verify -- "refs/remotes/${default_remote}/${current_branch}" || echo "false")
  remote_response=$?
  if [ "${local_result}" != 'false' ]; then
    # verify the result isn't an error
    if [ ${local_response} -gt 0 ]; then
      echo -e "\x1B[91mA fatal error ${local_response} occurred when verifying if the local branch existed\x1B[0m"
    else
      is_local=1
    fi
  fi
  if [ "${remote_result}" != 'false' ]; then
    # verify the result isn't an error
    if [ ${remote_response} -gt 0 ]; then
      echo -e "\x1B[91mA fatal error ${remote_response} occurred when verifying if the remote branch existed\x1B[0m"
    else
      is_remote=1
    fi
  fi

}

#######################################
# Set the git directory based on
#   variables or current working
#   directory and prompt for a
#   directory if auto set does not work
# Globals:
#   directories
#   use_dir
#   in_git
# Arguments:
#   None
# Returns:
#   None
#######################################
function set_git_dir {
  local rc

  # check for valid use_dir
  if [ -d "${use_dir}" ]; then
    script_in_git_dir
    if [ "${in_git}" = 'true' ]; then
      return 0
    fi
  fi

  # loop through directories
  for dir in "${directories[@]}"; do
    # if directory is not empty and is a directory
    if [ -n "${dir}" ] && [ -d "${dir}" ]; then
      # change to directory
      cd ${dir}
      # check for inside git directory
      git rev-parse --is-inside-work-tree > /dev/null 2>&1
      rc=$?

      # if return code is 0, use this directory and break
      if [ "${rc}" -eq 0 ]; then
        use_dir="${dir}"
        break
      fi
    fi
  done

  if [ -z "${use_dir}" ] || [ ! -d "${use_dir}" ]; then
    # prompt last
    func_dir
  fi

  # check for directory existence
  if [ ! -d "${use_dir}" ]; then
    echo -e "\x1B[91mUnable to find directory ${use_dir}.\x1B[0m"
    sleep 2
    exit 1
  fi

  # check for git directory
  script_in_git_dir
  if [ "${in_git}" != 'true' ]; then
    # the directory is probably a valid directory, but it does not contain a repository
    func_dir
    if [ "${in_git}" != 'true' ]; then
      echo -e "\x1B[91mCurrent git directory [${use_dir}] is not a valid working tree\x1B[0m"
      sleep 2
      exit 2
    fi
  fi
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
# Log the git command
# Globals:
#   None
# Arguments:
#   Message
# Returns:
#   None
#######################################
function log_git() {
  if [ -z "${1}" ]; then
    echo -e "\x1B[91mA message must be provided to log the git command\x1B[0m"
  else
    datetimestamp
    echo -e "\x1B[35m${stamp} \x1B[96m${1}\x1B[0m" >> ${history_file}
  fi
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
is_local=0
is_remote=0
original_git_dir="${use_dir}"
prefix=''
prompt='MTSgit'
pull_result=99
stamp=''
version='1.47.1'

# check for command line arguments
if [ -n "${1}" ]; then
  case "${1}" in
    clone)
      git_clone "${2}" "${3}"
      ;;
    *)
      echo -e "\x1B[91mUnknown command line parameter '${1}'\x1B[0m"
      ;;
  esac
fi

set_git_dir

# set directory for history file location
cd ${use_dir}
cd ..

history_file="${PWD}/.mtsgit_history"
menu_temp=''
menu_file="${PWD}/mtstemp_menu"
menu_value=''

cd ${use_dir}

echo 'MTSgit: An interactive script for standard git commands'
echo -e "Version \x1B[94m${version}\x1B[0m"
echo '                    by Mike Rodarte'
echo
echo 'Type help for a list of available commands.'
echo 'Press <Enter> to execute the command.'
echo 'To set up for a non-default repository, execute dir and truth.'
echo

script_set_current
display_prompt
