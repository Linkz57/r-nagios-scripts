#!/bin/bash

## check_freenas_backup.sh
## version 0.1
## This is my second foray into writing a "Nagios plugin". It's nearly identical to the first.
## I can't figure out how to install other people's plugins, but writing my own seems doable.
## Anyway, this script was written to check up on another script (that someone else wrote) which runs on my FreeNAS server.
## cp /data/freenas-v1.db /mnt/vol1/config_backups/`date \+%Y\%m\%d`_`cat /etc/version | cut -d'-' -f2`_`cat /etc/version | cut -d'(' -f2 | cut -d')' -f1`.db
## As you can see, it is a very simple backup of any FreeNAS box older than Corral. If my box were to die... 
## ...I would reinstall FreeNAS, import the ZFS pool, import/copy that DB file, and I'm back in business. 30 minutes of downtime, tops.


## As you can see: my backups are named `date \+%Y\%m\%d` plus some other stuff.
## I want to make sure my newest backup is less than 15 days old.
tooLongSinceLastBackup=15
## To check this, let's first get the name of my newest backup via SSH
sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "\ls -tp /mnt/*/config_backups/ | grep -v / | sort -r | head -n 1 ")


sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "\ls -tp /mnt/*/config_backups/ | grep -v / | sort -r | head -n 1 " > /dev/null) 2>&1 )


## Let's make sure there are no errors, first. If so, tell Nagios to raise a warning.
if [ -z "$sshError" ] ; then
        ## Now that we have the name of the file (which contains the date it was created) let's convert it to epoch time, and compare it to our current time, then convert the difference to days, and finally make sure it is older than the age limit set above. All in one line.
        if [ $(echo "( $(date +%s) - $(date -d $($sshOutput | awk -F '[_]' '{ print $1 }') +%s) ) / 86400" | bc) -lt $tooLongSinceLastBackup ]> /dev/null ; then
                echo "OK - It has been $(printf "( $(date +%s) - $(date -d $($sshOutput | awk -F '[_]' '{ print $1 }') +%s) ) / 86400" | bc) days since the last OS settings backup."
                exit 0
        else
                echo "CRITICAL - It has been $(printf "( $(date +%s) - $(date -d $($sshOutput | awk -F '[_]' '{ print $1 }') +%s) ) / 86400" | bc) days since the last OS settings backup."
                exit 2
        fi
else
        echo Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a server to monitor - $sshError
        exit 1
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
