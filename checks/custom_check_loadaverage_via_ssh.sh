#!/bin/bash

## custom_check_loadaverage_via_ssh.sh
## version 0.1
## $1 is ssh username
## $2 is ssh address


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "systemctl status $3" > /dev/null) 2>&1 )


if [ -z "$sshError" ] ; then
        sshOutput=$(ssh -o ConnectTimeout=10 -o BatchMode=yes $1@$2 "cat /proc/loadavg" > /dev/null)
#       min1=$(echo $sshOutput | awk '{print $1}')
        min5=$(echo $sshOutput | awk '{print $2}')
        min5m=$(echo $sshOutput | awk '{print $2 * 10}')
        min15=$(echo $sshOutput | awk '{print $3}')
        min15m=$(echo $sshOutput | awk '{print $3 * 10}')

#       echo $min15 | awk -v haddress=$2 '{if ($1>5.0) {print "CRITICAL - The 15 minute load average is at $1 which is above 5. " haddress " is probably not doing its job, or anything for that matter." system("exit 2");} ;}'
#       echo $min5 | awk '{if ($1<1.0) {print "OK - The 5 minute load average is at $1 which is below 1" err = 0;} else print "WARNING - The 5 minute load average is at $1 which is at or above 1" system("exit 1");}END {exit err'

        if [$min15m -gt 50] ; then
                echo "CRITICAL - The 15 minute load average is at $min15 which is above 5. $2 is probably not doing its job, or anything else for that matter."
                exit 2
        fi
        if [$min5m -lt 10] ; then
                echo "OK - The 5 minute load average is at $min5 which is below 1"
                exit 0
        else
                echo "WARNING - The 5 minute load average is at $min5 which is at or above 1"
                exit 1
        fi

else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
