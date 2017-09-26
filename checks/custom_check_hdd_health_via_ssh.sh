#!/bin/bash

## custom_check_hdd_health_via_ssh.sh
## version 0.2
##
## On the machine to be checked I have installed smartmontools release 6.2 SVN rev 4394
## On this same machine I run a long SMART test scheduled with a line in the crontab reading
## 0 21 * * SAT /usr/sbin/smartctl -t long /dev/sda
## This test happens every Saturday night, and Nagios checks the results of that test more often than it probably should.
##
## $1 is ssh username
## $2 is ssh address
## $3 is the hdd as in "sda" or "sdb"


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "smartctl -l selftest /dev/$3" > /dev/null) 2>&1 )
sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "smartctl -l selftest /dev/$3")


if [ -z "$sshError" ] ; then
        if echo $sshOutput | head -n 7 | grep "Completed without error" > /dev/null ; then
                echo "OK - /dev/$3 looks healthy"
                exit 0
        else
                echo "WARNING - $sshOutput"
                exit 1
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
