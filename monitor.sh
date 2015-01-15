#!/bin/bash
# monitor script by Mike Rodarte
#
# Check ping, web, and SSH (ports) for specified domains

################################################################################
#
# Configure the options below
# Add domain names to the list, separated by a space
domains=(example.com)
# SSH Ports (at least one of these should be open)
sshPorts=(22)
# Output file
outFile="monitor.log"
# admin email address
adminEmail="server_monitor@localhost"
# End Configuration
#
################################################################################

# result variables
resultPing=null
resultWeb=null
resultSsh=null
hasFail=0

# set the date
date=`date +"%Y-%m-%d %T"`

echo "Monitor servers - $date" > $outFile

function get_date {
    date=`date +"%Y-%m-%d %T"`
}

function ping_check() {
    domain=$1

    if [[ ${#domain} -eq 0 ]]; then
        echo "please specify a domain name with -d example.com"
        exit
    fi

    # script taken from
    # http://stackoverflow.com/questions/6118948/bash-loop-ping-successful#answer-6119043
    # and modified to handle the domain variable and show no output
    ((count = 100))                            # Maximum number to try.
    while [[ $count -ne 0 ]] ; do
        ping -c 1 -q $domain > /dev/null       # Try once.
        rc=$?
        if [[ $rc -eq 0 ]] ; then
            ((count = 1))                      # If okay, flag to exit loop.
        fi
        ((count = count - 1))                  # So we don't go forever.
    done

    if [[ $rc -eq 0 ]] ; then                  # Make final determination.
        resultPing="pass"
    else
        resultPing="fail"
        hasFail=1
    fi
}

function web_check() {
    domain=$1

    if [[ ${#domain} -eq 0 ]]; then
        echo "please specify a domain name with -d example.com"
        exit
    fi

    file="${domain}.index"
    wget -O $file -q $domain > /dev/null 2>&1
    rs=$?
    if [[ $rs -gt 0 ]]; then
        resultWeb="fail"
        hasFail=1
    else
        resultWeb="pass"
    fi
    rm $file
}

function ssh_check() {
    domain=$1

    if [[ ${#domain} -eq 0 ]]; then
        echo "please specify a domain name with -d example.com"
        exit
    fi

    resultSsh="fail"
    for p in "${sshPorts[@]}"; do
        nc -zw 1 $domain $p > /dev/null
        if [[ $? -eq 0 ]]; then
            resultSsh="pass"
            break
        fi
    done
    
    if [[ "$resultSsh" == "fail" ]]; then
        hasFail=1
    fi
}

for d in "${domains[@]}"; do
    echo "$d" >> $outFile

    # reset result variables
    resultPing=null
    resultWeb=null
    resultSsh=null
    
    # call functions
    ping_check $d
    web_check $d
    ssh_check $d

    # display results
    echo "    ping: ${resultPing}" >> $outFile
    echo "    web: ${resultWeb}" >> $outFile
    echo "    ssh: ${resultSsh}" >> $outFile
done

# only send an email if there was some sort of failure
if [[ ${hasFail} -eq 1 ]]; then
    subject="Server Monitor"
    host=$(hostname)
    from="monitor@${host}"
    msg=$(cat $outFile)
    mail="subject:${subject}\nfrom:${from}\n${msg}"
    echo -e $mail | /usr/sbin/sendmail "$adminEmail"
fi

get_date
echo "Finished: $date" >> $outFile

cat $outFile
