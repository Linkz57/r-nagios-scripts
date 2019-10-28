#!/bin/bash

## custom_check_process_is_running.sh
## version 0.1
## $1 is ssh username
## $2 is ssh address
## $3 is the process to grep for. use \| to seperate multiple processes. No spaces.


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "ps x" > /dev/null) 2>&1 )
sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "ps x")


if [ -z "$sshError" ] ; then
        if echo "$sshOutput" | grep "$3" > /dev/null ; then
		runningProcess=$(echo "$sshOutput" | grep $3 | awk '{print $5}')
                echo "OK - $runningProcess is running"
                exit 0
        else
                echo "CRITICAL - None of the following processes are running: $3"
                exit 2
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 3
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
