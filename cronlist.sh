#!/bin/bash
# https://gist.github.com/mts7/8f0aac241a22e08e3f15d4a19233f21c

# System-wide crontab file and cron job directory. Change these for your system.
CRONTAB='/etc/crontab'
CRONDIR='/etc/cron.d'

# Single tab character. Annoyingly necessary.
tab=$(echo -en "\t")

# Given a stream of crontab lines, exclude non-cron job lines, replace
# whitespace characters with a single space, and remove any spaces from the
# beginning of each line.
function clean_cron_lines() {
    while read line ; do
        echo "${line}" |
            egrep --invert-match '^($|\s*#|\s*[[:alnum:]_]+=)' |
            sed --regexp-extended "s/\s+/ /g" |
            sed --regexp-extended "s/^ //"
    done;
}

# Given a stream of cleaned crontab lines, echo any that don't include the
# run-parts command, and for those that do, show each job file in the run-parts
# directory as if it were scheduled explicitly.
function lookup_run_parts() {
    while read line ; do
        match=$(echo "${line}" | egrep -o 'run-parts (-{1,2}\S+ )*\S+')

        if [[ -z "${match}" ]] ; then
            echo "${line}"
        else
            cron_fields=$(echo "${line}" | cut -f1-6 -d' ')
            cron_job_dir=$(echo  "${match}" | awk '{print $NF}')

            if [[ -d "${cron_job_dir}" ]] ; then
                for cron_job_file in "${cron_job_dir}"/* ; do  # */ <not a comment>
                    [[ -f "${cron_job_file}" ]] && echo "${cron_fields} ${cron_job_file}"
                done
            fi
        fi
    done;
}

# Temporary file for crontab lines.
temp=$(mktemp) || exit 1

# Add all of the jobs from the system-wide crontab file.
cat "${CRONTAB}" | clean_cron_lines | lookup_run_parts >"${temp}"

# Add all of the jobs from the system-wide cron directory.
cat "${CRONDIR}"/* | clean_cron_lines >>"${temp}"  # */ <not a comment>

# Add each user's crontab (if it exists). Insert the user's name between the
# five time fields and the command.
while read user ; do
    crontab -l -u "${user}" 2>/dev/null |
        clean_cron_lines |
        sed --regexp-extended "s/^((\S+ +){5})(.+)$/\1${user} \3/" >>"${temp}"
done < <((cut --fields=1 --delimiter=: /etc/passwd && find /home/ -maxdepth 1 -mindepth 1 -type d -printf "%f\n") | sort | uniq)

# Note from fagut on 2014-11-12
# Hourly, Daily, Weekly and Monthly scripts
CRONDIR_HOURLY='/etc/cron.hourly'
CRONDIR_DAILY='/etc/cron.daily'
CRONDIR_WEEKLY='/etc/cron.weekly'
CRONDIR_MONTHLY='/etc/cron.monthly'

ls -lR "${CRONDIR_HOURLY}" | grep "^-" | awk -v dir="${CRONDIR_HOURLY}" {'print "01 * * * * root "dir"/" $9'} >>"${temp}"
ls -lR "${CRONDIR_DAILY}" | grep "^-" | awk -v dir="${CRONDIR_DAILY}" {'print "02 4 * * * root "dir"/" $9'} >>"${temp}"
ls -lR "${CRONDIR_WEEKLY}" | grep "^-" | awk -v dir="${CRONDIR_WEEKLY}" {'print "22 4 * * 0 root "dir"/" $9'} >>"${temp}"
ls -lR "${CRONDIR_MONTHLY}" | grep "^-" | awk -v dir="${CRONDIR_MONTHLY}" {'print "42 4 1 * * root "dir"/" $9'} >>"${temp}"
# End note from fagut

# Sort argument update by mts7
# handle --sort flag
if [ -n "$1" ]; then
    if [ "$1" = "--sort" ]; then
        case "$2" in
            time) mod='--numeric-sort'; keys='2,1';;
            user) mod=''; keys='6';;
        esac
    fi
fi
# End sort argument update by mts7

# Output the collected crontab lines. Replace the single spaces between the
# fields with tab characters, sort the lines by hour and minute or user,
# insert the header line, and format the results as a table.
cat "${temp}" |
    sed --regexp-extended "s/^(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(\S+) +(.*)$/\1\t\2\t\3\t\4\t\5\t\6\t\7/" |
    sort $mod --field-separator="${tab}" --key=${keys} |
    sed "1i\mi\th\td\tm\tw\tuser\tcommand" |
    column -s"${tab}" -t

rm --force "${temp}"
