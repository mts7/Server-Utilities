#!/bin/bash
# Author: Mike Rodarte
#
# Interactive script for git shortcuts and scripts

if [ -e ~/.bashrc ]; then
  . ~/.bashrc
fi

# Variables BEGIN
# User Variables
gitDir=${gitDir:-'/var/www/html'}
default_truth='master'
default_prod_server='production'
# Variables END

function display_prompt {
  set_current

  echo
  read -p $'\e[95m'"$prompt"$'\e[36m'" $current_branch"$'\e[95m'"> "$'\e[0m' choice
  datetimestamp
  echo -e "\e[35m$stamp\e[0m $choice\e[0m" >> $history_file
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
    status) git_status;;
    switch) git_switch;;
    undo) git_undo;;
    *) echo -e "\e[91mUnknown command $choice\e[0m";show_commands;;
  esac
}

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
  echo 'status              List the files changed and need to be added'
  echo 'switch              Switch to a branch*'
  echo 'undo                Undo a commit'
  echo
  echo '* shows commands that accept the menu parameter at some branch prompts'

  display_prompt
}

function git_add {
  cd $gitDir

  read -e -p 'file name: ' files
  if [ -n "$files" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> $history_file
  fi

  i="0"
  while [ -z $files ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    # show result of "git status" to help indicate what should be added
    if [ $i -eq 1 ]; then
      git status -s
    fi
    read -e -p $'\e[91mPlease specify a file name: \e[0m' files
    if [ -n "$files" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> $history_file
    fi
  done

  if [ -z $files ]; then
    echo -e "\e[91mA file name was not specified"
  else
    git add $files
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with add"
    fi
  fi

  display_prompt
}

function git_changes {
  cd $gitDir

  read -p "branch or commit name [${default_branch}]: " changed
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$changed\e[0m" >> $history_file
  changed=${changed:-$default_branch}

  if [ "$changed" = "menu" ]; then
    menu_branch
    changed="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    changed=${changed:-$default_branch}
  fi

  read -p "source of truth name [${default_truth}]: " truth
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> $history_file
  truth=${truth:-$default_truth}

  git diff --name-only $changed $truth
  rc=$?
  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with diff"
  fi

  display_prompt
}

function git_commit {
  cd $gitDir

  read -p "message: " message
  if [ -n "$message" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> $history_file
  fi

  i="0"
  while [ -z $message ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a commit message: \e[0m' message
    if [ -n "$message" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> $history_file
    fi
  done

  if [ -z $message ]; then
    echo -e "\e[91mPlease commit with a message"
  else
    git commit -a -m "$message"
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with commit"
    fi
  fi

  display_prompt
}

function git_create {
  cd $gitDir

  read -p "new branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> $history_file
  branch=${branch:-$default_branch}

  git checkout $default_truth
  rc=$?
  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with checking out $default_truth"
  else
    git pull --no-rebase -v "origin"
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting branch create."
    else
      git checkout -b $branch
      rc=$?
      if [ $rc -gt 0 ]; then
        echo -e "\e[91mError [$rc]; failed to create branch"
      else
        echo -e "\e[92mCreated $branch"
      fi
    fi
  fi

  display_prompt
}

function git_current {
  cd $gitDir

  set_current
  echo -e "\e[36m$current_branch"

  display_prompt
}

function git_delete {
  cd $gitDir

  git checkout $default_truth

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> $history_file
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  to_delete=1
  if [ "$branch" = $default_truth ]; then
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

  if [ $to_delete -eq 1 ]; then
    git branch -D $branch
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not delete branch $branch"
    fi
  else
    echo -e "\e[93mSkipping deletion of $branch"
  fi

  display_prompt
}

function git_deploy {
  cd ${gitDir}

  read -p "code branch name [${default_branch}]: " branchCode
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branchCode\e[0m" >> ${history_file}
  branchCode=${branchCode:-$default_branch}

  if [ "$branchCode" = "menu" ]; then
    menu_branch
    branchCode="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branchCode=${branchCode:-$default_branch}
  fi

  read -p "server branch name: " branchServer
  if [ -n "$branchServer" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${branchServer} ]
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
    read -p $'\e[91mPlease specify a server branch name: \e[0m' branchServer
    if [ -n "$branchServer" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${branchServer} ]; then
    echo -e "\e[91mError: A branch name must be provided\e[0m"
  else
    defaultDeploy="${default_prod_server}/${default_truth}"
    read -p "deployment server branch name [${defaultDeploy}]: " deployServer
    deployServer=${deployServer:-$defaultDeploy}

    script_comment "Switching to $branchServer"
    git checkout ${branchServer}
    script_comment "Merging $branchCode to $branchServer"
    git merge ${branchCode}
    script_comment "Pushing ${default_truth} to $branchServer"
    git push origin ${default_truth}:${default_truth}
    script_comment "Switching to $deployServer"
    git checkout ${deployServer}
    script_comment "Merging $branchCode to $deployServer"
    git merge ${branchCode}
    script_comment "Pushing ${default_truth} to $deployServer"
    git push ${default_prod_server} ${default_truth}:${default_truth}
    script_comment "Switching to $branchServer"
    git checkout ${branchServer}
  fi

  display_prompt
}

function git_list {
  cd $gitDir

  read -p 'remote [y/n]: ' remote
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$remote\e[0m" >> $history_file

  command='git branch'

  read -p "filter: " filter
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$filter\e[0m" >> $history_file

  if [ "$remote" = "y" ]; then
    command="$command -r"

    # check for new branches that were pushed since the last pull
    echo -e "\e[36mChecking for remote branches...\e[0m"
    echo
    git checkout $default_truth
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] checking out $branch\e[0m"
    else
      git pull --no-rebase -v "origin"
      rc=$?
      if [ $rc -gt 0 ]; then
        echo -e "\e[91mError [$rc] with pull\e[0m"
      fi
    fi
    echo
    echo -e "\e[33mRemote Branches\e[0m"
  elif [ "$remote" != "n" ]; then
    echo -e "\e[91mInvalid response\e[0m"
  else
    echo
    echo -e "\e[33mLocal Branches\e[0m"
  fi

  if [ ! -z $filter ]; then
    command="$command | grep $filter"
  fi

  eval ${command}
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not list branches\e[0m"
  fi

  display_prompt
}

function git_log {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> $history_file
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  read -p "author (blank for all): " author
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$author\e[0m" >> $history_file

  read -e -p "file relative to repo root (blank for all): " file
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$file\e[0m" >> $history_file

  default_days=7
  read -p "days ago [${default_days}]: " days
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$days\e[0m" >> $history_file

  if [ "$days" -eq "$days" ] > /dev/null 2>&1
  then
    days=$days
  else
    days=$default_days
  fi
  days_ago=$(date --date="$days days ago" +"%Y"-"%m"-"%d")

  git checkout $branch
  rc=$?
  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not checkout $branch\e[0m"
  else
    file_cmd=''
    if [ -n "$file" ]; then
      file_cmd=" --follow -p $file"
    fi
    git log --stat --graph --author=${author} --since="$days_ago" $file_cmd
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not get log\e[0m"
    fi
  fi

  display_prompt
}

function git_merge {
  cd ${gitDir}

  read -p "code branch name [${default_branch}]: " branchCode
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branchCode\e[0m" >> ${history_file}
  branchCode=${branchCode:-$default_branch}

  if [ "$branchCode" = "menu" ]; then
    menu_branch
    branchCode="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branchCode=${branchCode:-$default_branch}
  fi

  read -p "server branch name: " branchServer
  if [ -n "$branchServer" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> ${history_file}
  fi

  i="0"
  while [ -z ${branchServer} ]
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
    read -p $'\e[91mPlease specify a server branch name: \e[0m' branchServer
    if [ -n "$branchServer" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> ${history_file}
    fi
  done

  if [ -z ${branchServer} ]; then
    echo -e "\e[91mA server branch name must be specified\e[0m"
  else
    func_merge ${branchCode} ${branchServer}
  fi

  display_prompt
}

function git_message {
  cd $gitDir

  read -p 'new commit message: ' message
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> $history_file

  if [ -n "$message" ]; then
    git commit --amend -m "$message"

    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError amending the commit message\e[0m"
    fi
  fi

  display_prompt
}

function git_pull {
  cd $gitDir

  git pull --no-rebase -v "origin"
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with pull\e[0m"
  fi

  display_prompt
}

function git_push {
  cd ${gitDir}

  defaultServer='origin'
  read -p "server [$defaultServer]: " server
  server=${server:-$defaultServer}

  func_push ${server}

  display_prompt
}

function git_remote {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> $history_file
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ -z $branch ]; then
    echo -e "\e[91Please enter a branch name\e[0m"
  else
    git push -u origin $branch
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] making branch $branch remote\e[0m"
    fi
  fi

  display_prompt
}

function git_reset {
  cd $gitDir

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> $history_file
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  if [ "$branch" != "$current_branch" ]; then
    git checkout $branch
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] checking out $branch"
      echo "using $current_branch instead of $branch"
      branch="$current_branch"
    fi
    script_set_current
  fi

  read -p 'commit name: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> $history_file

  if [ "$commit" = "menu" ]; then
    menu_commit
    commit="$menuValue"
  fi

  read -p "Are you sure you want to reset $branch? [y/n] " answer
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$answer\e[0m" >> $history_file

  if [ "$answer" = 'y' ]; then
    git reset --hard $commit
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with reset\e[0m"
    else
      echo -e "\e[92mReset the branch\e[0m"
    fi
  fi

  display_prompt
}

function git_restore {
  cd $gitDir

  git stash pop
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] popping from the stash\e[0m"
  fi

  display_prompt
}

function git_revert {
  cd ${gitDir}

  read -p 'commit to revert: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> ${history_file}

  if [ "$commit" = "menu" ]; then
    menu_commit
    commit="$menuValue"
  fi

  if [ -z "$commit" ]; then
    echo -e "\e[91mA commit number must be provided\e[0m"
  else
    git revert ${commit}

    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] reverting commit $commit\e[0m"
    else
      func_push
    fi
  fi

  display_prompt
}

function git_save {
  cd $gitDir

  git stash save
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] saving to the stash\e[0m"
  fi

  display_prompt
}

function git_status {
  cd $gitDir

  git status -s

  display_prompt
}

function git_switch {
  cd ${gitDir}

  read -p "branch name [${default_branch}]: " branch
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branch\e[0m" >> ${history_file}
  branch=${branch:-$default_branch}

  if [ "$branch" = "menu" ]; then
    menu_branch
    branch="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branch=${branch:-$default_branch}
  fi

  func_switch ${branch}

  display_prompt
}

function git_undo {
  cd $gitDir

  git reset --soft HEAD
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with reset\e[0m"
  else
    echo -e "\e[92mRemoved the commit\e[0m"
  fi

  display_prompt
}

function func_merge {
  script_comment "func_merge($1, $2)"
  branchCode="$1"
  branchServer="$2"

  git checkout ${branchServer}
  rc=$?
  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc]; could not switch to $branchServer\e[0m"
  else
    git merge ${branchCode}
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting branch merge\e[0m"
      echo -e "\e[93mPlease fix the conflicts and then push\e[0m"
    else
      func_push "origin $branchServer:$branchServer"
    fi
  fi
}

function func_push {
  script_comment "func_push($1)"
  if [ -z "$1" ]; then
    server=''
  else
    server="$1"
  fi

  git pull --no-rebase -v "origin"
  rc=$?
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

function func_switch {
  script_comment "func_switch($1)"
  branch="$1"

  git checkout ${branch}
  rc=$?

  if [ ${rc} -gt 0 ]; then
    echo -e "\e[91mError [$rc] checking out $branch\e[0m"
  else
    git pull --no-rebase -v "origin"
    rc=$?
    if [ ${rc} -gt 0 ]; then
      echo -e "\e[91mError [$rc] with pull\e[0m"
    fi
  fi
}

function menu_adjust_branch () {
  if [ -z "$1" ]; then
    return 1
  else
    localBranch="$1"

    # trim leading spaces from the branch name
    localBranch=`echo "$localBranch" | xargs`
  fi

  menuValue="${localBranch}"
}

function menu_adjust_commit () {
  if [ -z "$1" ]; then
    return 1
  else
    value="$1"
  fi

  menuValue="${value:0:7}"
}

function menu_branch {
  cd $gitDir

  menu_display "git branch | egrep '${prefix}-' > $menuFile" 'branch number' 30 'menu_adjust_branch'
}

function menu_commit {
  cd $gitDir

  menu_display "git log --oneline --decorate -10 > $menuFile" 'commit number' 10 'menu_adjust_commit'
}

function menu_display () {
  cd $gitDir

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
    menuPrompt="$2"
  fi

  if [ -z "$3" ]; then
    echo -e "\e[91mmenu_display was called without a number of items parameter"
    return 3
  else
    itemNumbers="$3"
  fi

  if [ -z "$4" ]; then
    echo -e "\e[91mmenu_display was called without a value manipulation function parameter"
    return 4
  else
    menuFunction="$4"
  fi

  # execute the command and write the contents to the menuFile
  eval "${command}"

  # prepare lines for menu usage
  menuTemp=`cat $menuFile`

  # loop through file to display items and their corresponding index in menuTemp
  i=0
  while read line; do
    if [ $i -eq $itemNumbers ]; then
      break
    fi
    i=$[$i+1]
    printf "%2s: %s\n" "$i" "$line"
  done < "$menuFile"

  read -p "${menuPrompt}: " menuItem
  if [ -n "$menuItem" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$menuItem\e[0m" >> $history_file
  fi

  # give the user 3 chances to enter something valid
  i=0
  while [ -z $menuItem ]; do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a number of a ${menuPrompt} menu item: \e[0m' menuItem
    if [ -n "$menuItem" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$menuItem\e[0m" >> $history_file
    fi
  done

  if [ -z $menuItem ]; then
    echo -e "\e[91mA ${menuPrompt} menu item number must be specified\e[0m"
  else
    # get the value from the file at the specified line
    value=$(sed "${menuItem}q;d" $menuFile)
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with sed.\e[0m"
    else
      # check for current branch (denoted by "* " before the branch name)
      first=$(echo "${value}" | cut -d' ' -f 1)
      if [ "$first" = "*" ]; then
        value="${value:2}"
      fi

      # execute function with this value
      eval $menuFunction "$value"

      echo "using value $menuValue"
    fi
  fi
}

function script_comment {
  echo -e "\e[100m${1}\e[0m"
}

# TODO: save $gitDir to ~/.bashrc
function script_dir {
  read -e -p "Please specify the git directory[${gitDir}]: " gitDir

  i="0"
  while [ ! -d "$gitDir" ]; do
    if [ $i -eq 5 ]; then
      echo -e "\e[91mPlease specify the correct git directory and try again.\e[0m"
      break
    fi
    i=$[$i+1]

    read -e -p 'Please specify the git directory: ' gitDir
  done

  # check for git directory
  script_in_git_dir
  if [ "$inGit" != 'true' ]; then
    echo -e "\e[91mCurrent git directory [${gitDir}] is not a valid working tree\e[0m"
    gitDir="$originalGitDir"
  else
    history_file="$PWD/.mtsgit_history"
  fi

  display_prompt
}

function script_history {
  less +G -r -N $history_file

  display_prompt
}

function script_in_git_dir {
  cd $gitDir
  inGit=$(git rev-parse --is-inside-work-tree)
  rc=$?

  if [ $rc -gt 0 ]; then
    inGit='false'
  fi
}

function script_prefix {
  temp_array=(${default_branch//-/ })
  prefix="${temp_array[0]}"
}

function script_set {
  read -p "default branch [${current_branch}]: " default_branch
  default_branch=${default_branch:-$current_branch}

  echo -e "\e[92mSet default branch to \e[32m${default_branch}"

  script_prefix

  display_prompt
}

function script_set_current {
  set_current
  default_branch="$current_branch"
  script_prefix
}

function script_truth {
  read -p "default source of truth branch: " truth
  if [ -n "$truth" ]; then
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> $history_file
  fi

  i="0"
  while [ -z $truth ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify the source of truth: \e[0m' truth
    if [ -n "$truth" ]; then
      datetimestamp
      echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> $history_file
    fi
  done

  if [ -z $truth ]; then
    echo -e "\e[91mNo branch specified"
  else
    cd $gitDir

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

function script_variables {
  echo -e "\e[0mCurrent Variables"
  echo
  echo -e "gitDir: \e[33m$gitDir\e[0m"
  echo -e "prompt: \e[95m$prompt\e[0m"
  echo -e "default_branch: \e[32m$default_branch\e[0m"
  echo -e "default_truth: \e[96m$default_truth\e[0m"
  echo -e "current_branch: \e[36m$current_branch\e[0m"
  echo -e "default_prod_server: $default_prod_server\e[0m"
  echo -e "prefix: \e[35m$prefix\e[0m"
  echo -e "history_file: $history_file\e[0m"
  echo -e "version: \e[94m$version\e[0m"

  display_prompt
}

function set_current {
  current_branch=$(git rev-parse --abbrev-ref HEAD)
}

function datetimestamp {
  stamp=`date +%Y-%m-%d_%H:%M:%S`
}

function quit {
  rm -f $menuFile
  echo 'Thank you for using MTSgit'
  exit 0
}

# Script Variables
prompt='MTSgit'
default_branch=''
current_branch=''
prefix=''
version='1.34'
stamp=''
inGit=''
originalGitDir="$gitDir"

# check for directory existence
if [ ! -d "$gitDir" ]; then
  script_dir
  if [ ! -d "$gitDir" ]; then
    echo -e "\e[91mUnable to find directory $gitDir.\e[0m"
    sleep 3
    exit 1
  fi
fi

# check for git directory
script_in_git_dir
if [ "$inGit" != 'true' ]; then
  echo -e "\e[91mCurrent git directory [${gitDir}] is not a valid working tree\e[0m"
  sleep 5
  exit 2
fi

# set directory for history file location
cd $gitDir
cd ..

history_file="$PWD/.mtsgit_history"
menuTemp=''
menuFile="$PWD/mtstemp_menu"
menuValue=''

cd $gitDir

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
