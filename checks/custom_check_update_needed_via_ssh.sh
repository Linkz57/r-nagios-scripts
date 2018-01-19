#!/bin/bash

## custom_check_update_needed_via_ssh.sh
## version 1
## Check if updates are needed. Throws warning on regular updates, and may later crit on security updates
## Currently only supports Ubuntu



sshOutput=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "/usr/lib/update-notifier/apt-check") 2>&1)
regular=$(echo "$sshOutput" | cut -d';' -f1)
security=$(echo "$sshOutput" | cut -d';' -f2)


## Thanks to Mak Kolybabi for the two cuts above and the tests below
## https://superuser.com/questions/199869/check-number-of-pending-security-updates-in-ubuntu


if [ "$sshOutput" = "0;0" ] ; then
        echo "OK - Everything up to date"
        exit 0
fi


if [ "$security" != "0" ] ; then
        echo "$security security updates pending"
        exit 1
fi


if [ "$regular" != "0" ] ; then
        echo "$regular non-security updates pending"
        exit 1
fi

echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id before adding or editing a server to monitor - $sshError"
exit 2
