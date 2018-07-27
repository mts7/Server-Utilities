#!/bin/bash
# Find all directories named .git (which should be only git repositories)
# Ignore anything in /mnt/

find / -type d -name ".git" 2> >(grep -Ev 'Permission denied|No such file or directory' >&2) 

