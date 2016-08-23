#!/bin/bash
# Author: Mike Rodarte
#
# Interactive script for git shortcuts and scripts

. ~/.bashrc

# Variables BEGIN
gitDir=${gitDir:-'/var/www/html'}
prompt="MTSgit> "
default_branch=''
default_truth='master'
current_branch=''
prefix=''
version='1.25.2'
stamp=''

# set directory for history file location
cd $gitDir
cd ..

history_file="$PWD/.mtsgit_history"
menuTemp=''
menuFile="$PWD/mtstemp_branches"
menuValue=''
# Variables END

function display_prompt {
  set_current

  echo
  read -p $'\e[95m'"$prompt"$'\e[0m' choice
  datetimestamp
  echo -e "\e[35m$stamp\e[0m $choice\e[0m" >> $history_file
  case "$choice" in
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
  echo 'delete              Delete a branch'
  echo 'list                List branches'
  echo 'log                 Display the Commit History of a branch'
  echo 'merge               Merge two branches'
  echo 'message             Update a message to the last commit'
  echo 'pull                Fetch or merge changes with remote server'
  echo 'push                Push the current branch to origin'
  echo 'remote              Make a local branch remote'
  echo 'reset               Discard all changes and reset index and working tree'
  echo 'restore             Restore the latest stash'
  echo 'revert              Revert a commit'
  echo 'save                Stash the current changes'
  echo 'status              List the files changed and need to be added'
  echo 'switch              Switch to a branch'
  echo 'undo                Undo a commit'

  display_prompt
}

function git_add {
  cd $gitDir

  read -e -p 'file name: ' files
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> $history_file

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
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$files\e[0m" >> $history_file
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
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> $history_file

  i="0"
  while [ -z $message ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a commit message: \e[0m' message
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$message\e[0m" >> $history_file
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
      echo -e "\e[91mError [$rc] checking out $branch"
    else
      git pull
      rc=$?
      if [ $rc -gt 0 ]; then
        echo -e "\e[91mError [$rc] with pull"
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
    echo -e "\e[91mError [$rc]; could not list branches"
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
  read -e -p "file relative to bio-techne.com (blank for all): " file
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
    echo -e "\e[91mError [$rc]; could not checkout $branch"
  else
    file_cmd=''
    if [ -n "$file" ]; then
      file_cmd=" --follow -p $file"
    fi
    git log --stat --graph --author=${author} --since="$days_ago" $file_cmd
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not get log"
    fi
  fi

  display_prompt
}

function git_merge {
  cd $gitDir

  read -p "code branch name [${default_branch}]: " branchCode
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branchCode\e[0m" >> $history_file
  branchCode=${branchCode:-$default_branch}

  if [ "$branchCode" = "menu" ]; then
    menu_branch
    branchCode="$menuValue"

    # use the found branch or the default branch (if no branch was found)
    branchCode=${branchCode:-$default_branch}
  fi

  read -p "server branch name: " branchServer
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> $history_file

  i="0"
  while [ -z $branchServer ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    if [ $i -eq 1 ] && [ ! -z "$prefix" ]; then
      echo -e "\e[93mDid you mean one of these branches?\e[0m"
      # suggest a branch name
      command="git branch -r | egrep '${prefix}-[A-Z]+[0-9]*\b$'"
      eval ${command}
    fi
    read -p $'\e[91mPlease specify a server branch name: \e[0m' branchServer
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branchServer\e[0m" >> $history_file
  done

  if [ -z $branchServer ]; then
    echo -e "\e[91mA server branch name must be specified"
  else
    git checkout $branchServer
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; could not switch to $branchServer"
    else
      git merge $branchCode
      rc=$?
      if [ $rc -gt 0 ]; then
        echo -e "\e[91mError [$rc]; aborting branch merge"
        echo -e "\e[93mPlease fix the conflicts and then push"
      else
        git pull --no-rebase -v "origin"
        rc=$?
        if [ $rc -gt 0 ]; then
          echo -e "\e[91mError [$rc]; aborting pull after merge"
          echo -e "\e[93mPlease fix the issue and then push"
        else
          git push "origin" $branchServer:$branchServer
          rc=$?
          if [ $rc -gt 0 ]; then
            echo -e "\e[91mError [$rc]; could not push code with $branchServer"
          fi
        fi
      fi
    fi
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

  git pull
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with pull"
  fi

  display_prompt
}

function git_push {
  cd $gitDir

  git pull
  rc=$?
  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc]; aborting pull"
  else
    git push
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc]; aborting push after pull"
    fi
  fi

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
    git push -u $branch
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] making branch $branch remote"
    fi
  fi

  display_prompt
}

function git_reset {
  cd $gitDir

  read -p 'commit name: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> $history_file

  read -p "Are you sure you want to reset $default_branch? [y/n]" answer
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$answer\e[0m" >> $history_file

  if [ "$answer" = 'y' ]; then
    git reset --hard $commit
    rc=$?

    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with reset"
    else
      echo -e "\e[92mReset the branch"
    fi
  fi

  display_prompt
}

function git_restore {
  cd $gitDir

  git stash pop
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] popping from the stash"
  fi

  display_prompt
}

function git_revert {
  cd $gitDir

  read -p 'commit to revert: ' commit
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$commit\e[0m" >> $history_file

  if [ -z "$commit" ]; then
    echo -e "\e[91mA commit number must be provided"
  else
    git revert $commit

    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] reverting commit $commit"
    fi
  fi

  display_prompt
}

function git_save {
  cd $gitDir

  git stash save
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] saving to the stash"
  fi

  display_prompt
}

function git_status {
  cd $gitDir

  git status -s

  display_prompt
}

function git_switch {
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

  git checkout $branch
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] checking out $branch"
  else
    git pull
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with pull"
    fi
  fi

  display_prompt
}

function git_undo {
  cd $gitDir

  git reset --soft HEAD
  rc=$?

  if [ $rc -gt 0 ]; then
    echo -e "\e[91mError [$rc] with reset"
  else
    echo -e "\e[92mRemoved the commit"
  fi

  display_prompt
}

function menu_branch {
  menuFile='../mtstemp_branches'

  # write all of the current prefix's local branches to a file
  command="git branch | egrep '${prefix}-' > $menuFile"
  eval ${command}

  # prepare lines for menu usage
  menuTemp=`cat $menuFile`

  # loop through file to display branches and their corresponding index in menuTemp
  i=0
  while read line; do
    if [ $i -eq 30 ]; then
      break
    fi
    i=$[$i+1]
    printf "%2s: %s\n" "$i" "$line"
  done < "$menuFile"

  read -p "branch number: " branchMenuItem
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$branchMenuItem\e[0m" >> $history_file

  i="0"
  while [ -z $branchMenuItem ]; do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify a number of a branch menu item: \e[0m' branchMenuItem
    datetimestamp
    echo -e "\e[35m$stamp   \e[33m$branchMenuItem\e[0m" >> $history_file
  done

  if [ -z $branchMenuItem ]; then
    echo -e "\e[91mA local branch menu item number must be specified\e[0m"
  else
    # get the branch name from the file at the specified line
    localBranch=$(sed "${branchMenuItem}q;d" $menuFile)
    rc=$?
    if [ $rc -gt 0 ]; then
      echo -e "\e[91mError [$rc] with sed.\e[0m"
    else
      # trim leading spaces from the branch name
      localBranch=`echo "$localBranch" | xargs`

      # check for current branch (denoted by "* " before the branch name)
      first=$(echo "${localBranch}" | cut -d' ' -f 1)
      if [ "$first" = "*" ]; then
        localBranch="${localBranch:2}"
      fi

      echo "using branch $localBranch"

      # set global variable
      menuValue="$localBranch"
    fi
  fi

}

function script_history {
  less +G -r -N $history_file

  display_prompt
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
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> $history_file

  i="0"
  while [ -z $truth ]
  do
    if [ $i -eq 3 ]; then
      break
    fi
    i=$[$i+1]
    read -p $'\e[91mPlease specify the source of truth: \e[0m' truth
  datetimestamp
  echo -e "\e[35m$stamp   \e[33m$truth\e[0m" >> $history_file
  done

  if [ -z $truth ]; then
    echo -e "\e[91mNo branch specified"
  else
    cd $gitDir

    # check to see if the $truth branch actually exists before setting default
    lines=$(eval "git branch | egrep '^\s*${truth}$' | wc -l")
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

cd $gitDir

echo 'MTSgit: An interactive script for standard git commands'
echo -e "Version \e[94m${version}\e[0m"
echo '                    by Mike Rodarte'
echo
echo 'Type help for a list of available commands.'
echo 'Press <Enter> to execute the command.'
echo

script_set_current
display_prompt
