#!/bin/bash

## custom_check_process_hdd_health.sh
## version 0.2
##
## $1 is ssh username
## $2 is ssh address
## $3 is the memory you want to check for (either Swap or Mem)


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "free" > /dev/null) 2>&1 )
sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "free")
percentage=$(echo $sshOutput | grep $3 | awk '{ percent = $3 / $2 ; print $percent}')

if [ -z "$sshError" ] ; then
        if (("$percentage" < "30")) ; then
                echo "OK - consuming $percent percent of $3"
                exit 0
        elif (("$percentage" < "60"))
                echo "WARNING - consuming $percent percent of $3"
                exit 1
        else
                echo "CRITICAL - consuming $percent percent of $3"
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
