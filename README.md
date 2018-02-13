Server-Utilities
================

Files
================
server-check

dbdump

fix-yum

remove-duplicates

monitor.sh

mtsgit.sh

---

server-check
================
Use this tool to view current usage statistics for the server and/or set up as 
a cron job.

Author: Mike Rodarte

Created: 2014-10-06

Please update this as you see fit. There are probably many other ways to achieve
the same thing. Your comments are welcome.

Usage
--------------------
Edit the configuration variables at the top of the file.

Add the file to your cron list.

Variables
--------------------
dir: directory to use for temporary files

from: from email address (for sending alerts)

to: to email address (for sending alerts)

fs: file system to check for disk usage

cpuLevel: minimum load average to trigger alert

diskLevel: minimum disk usage to trigger alert

memLevel: minimum memory usage to trigger alert

---

dbdump
===============
Use this tool to dump a MySQL database on localhost to a file.

Author: Mike Rodarte

Created: 2014-11-18

Usage
------------------
Edit the configuration variables at the top of the file.

Follow the prompts.

---

fix-yum
===============
Use this tool to fix yum updates. This was created to get around the yum error: 
Couldn't fork, Cannot allocate memory. It requires remove-duplicates to work.

Author: Mike Rodarte

Created: 2014-11-25

Usage
------------------
Edit the configuration variable at the top of the file, then run the file.

---

remove-duplicates
===============
This is a dependency of fix-yum and is not to be run on its own, though it 
can be independent of all other scripts.

Author: Mike Rodarte

Created: 2014-11-25

Usage
------------------
Pass a package name as an argument to remove that package. 

---

monitor.sh
===============
Add this to your cron jobs so it will notify you when a service on a server is down.

Author: Mike Rodarte

Created: 2015-01-15

Usage
------------------
Edit the configuration variables at the top of the file, then add the file to crontab.

---

mtsgit.sh
===============
This script is an on-going script with a prompt so that the actual shell is not directly used.
Simplify git commands to one-word statements like pull and push instead of the longer versions.
Combine commands like git pull before doing git push into a single command of push.
Use the help menu to see all available options with descriptions of how they work.

Author: Mike Rodarte

Created: 2016-07-11

Usage
------------------
Run mtsgit.sh

Type `dir` to set the git directory for the repository.

Type `truth` to set the default source of truth (like master).

For simpler startup, create a user variable called `$git_dir` in your `.bashrc` file that is set to that directory.
Update the script to use your default source of truth branch (like master) if you want to use something other than what is provided.
![mtsgit variables](https://ilj.co/images/mtsgit-variables-1.42.png)


Type `help` to see a list of commands available.
Some commands accept the string `menu` to list either branches or commits. 
Those will be noted with `*` in the help menu.
![mtsgit help](https://ilj.co/images/mtsgit-help-1.42.png)
