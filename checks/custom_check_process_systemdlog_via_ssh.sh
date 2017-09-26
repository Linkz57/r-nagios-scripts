#!/bin/bash

## custom_check_process_systemdlog_via_ssh.sh
## version 0.1
## $1 is ssh username
## $2 is ssh address
## $3 is the process name to check
## $4 is usual log entries to ignore


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "systemctl status $3" > /dev/null) 2>&1 )


if [ -z "$sshError" ] ; then
        ## TODO: save the ssh output as a variable and grep it maybe. Figure out how to parse arguments with spaces. Apparently the secret is "$*" whatever that means.
        if ssh -o ConnectTimeout=10 -o BatchMode=yes $1@$2 "journalctl -u $3 | grep -v "$4"" > /dev/null ; then
                echo "WARNING - $3 has some unusal log entries at $2 that may be worth looking in to. If running journalctl -u $3 shows nothing unusual, modify the Nagios host config file for $HOSTNAME$"
                ## since that grep failed to find anything a human said to ignore, we can assume that everything is fine because the log only contains expected entries.
                exit 1
        else
                echo "OK - The log files of $3 look fine at $2"
                exit 0
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
