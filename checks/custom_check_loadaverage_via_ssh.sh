#!/bin/bash

## custom_check_loadaverage_via_ssh.sh
## version 0.8
## $1 is ssh username
## $2 is ssh address

## As far as I know, CPU load is measured in the average number of processes in line for the CPU to get to their requests.
## So if your single-core machine has a load of 0.5 it means that half the time there's nothing going on, and half the time there's a single process being served. 
## This is great, because that 0.5 means 50% work for a single core.
## If your dual-core machine has a load of 0.5 it means that the two processes with their combined power of 200% are spending a combined 75% time doing nothing.
## This is twice as nice, because that 0.5 means 50% work for a sinlge core, but you have two cores.
## For this reason (again, as far as I know), a good load number would average less than 1 process waiting in line for each core.
## I'll worry about how many cores you have, you decide now how high a load average is too high
loadWarning=1
loadCritical=5



## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /proc/loadavg" > /dev/null) 2>&1 )



#if [ $(echo "`cut -f1 -d ' ' /proc/loadavg` < $threshold" | bc) -eq 1 ]; then


if [ -z "$sshError" ] ; then
        sshOutput=$(ssh -o ConnectTimeout=10 -o BatchMode=yes "$1"@"$2" "cat /proc/loadavg && grep -c ^processor /proc/cpuinfo 2>/dev/null")
#       min1=$(echo "$sshOutput" | head -n1 | awk '{print $1}')
#       min1m=$(echo "$sshOutput" | head -n1 | awk '{print $1 * 100}')
        min5=$(echo "$sshOutput" | head -n1 | awk '{print $2}')
        min5m=$(echo "$sshOutput" | head -n1 | awk '{print $2 * 100}')
        min15=$(echo "$sshOutput" | head -n1 | awk '{print $3}')
        min15m=$(echo "$sshOutput" | head -n1 | awk '{print $3 * 100}')

        loadWarningM=$(echo "$loadWarning"00)
        loadCriticalM=$(echo "$loadCritical"00)

        cores=$(echo "$sshOutput" | tail -n1)
        [ "$cores" -eq "0" ] 2>/dev/null && cores=1
        threshold="${cores:-1}"

#       echo $min15 | awk -v haddress=$2 '{if ($1>5.0) {print "CRITICAL - The 15 minute load average is at $1 which is above 5. " haddress " is probably not doing its job, or anything for that matter." system("exit 2");} ;}'
#       echo $min5 | awk '{if ($1<1.0) {print "OK - The 5 minute load average is at $1 which is below 1" err = 0;} else print "WARNING - The 5 minute load average is at $1 which is at or above 1" system("exit 1");}END {exit err'

        if (( "$min15m" > ( "loadCriticalM" * "$threshold" ) )) ; then
                echo "CRITICAL - The 15 minute load average is at $min15 which is above $loadCritical. $2 is probably not doing its job, or anything else for that matter."
                exit 2
        fi
        if (( "$min5m" < ( "loadWarningM" * "$threshold" ) )) ; then
                echo "OK - The 5 minute load average is at $min5 which is below $loadWarning"
                exit 0
        else
                echo "WARNING - The 5 minute load average is at $min5 which is at or above $loadWarning"
                exit 1
        fi

else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
