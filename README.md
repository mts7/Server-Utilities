Server-Utilities
================

Use this tool to view current usage statistics for the server and/or set up as 
a cron job.

Author: Mike Rodarte

Created: 2014-10-06

Please update this as you see fit. There are probably many other ways to achieve
the same thing. Your comments are welcome.

Usage
====================
Edit the configuration variables at the top of the file.
Add the file to your cron list.

Variables
====================
dir: directory to use for temporary files

from: from email address (for sending alerts)

to: to email address (for sending alerts)

fs: file system to check for disk usage

cpuLevel: minimum load average to trigger alert

diskLevel: minimum disk usage to trigger alert

memLevel: minimum memory usage to trigger alert