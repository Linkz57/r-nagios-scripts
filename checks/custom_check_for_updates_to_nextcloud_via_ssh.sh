#!/bin/bash

## custom_check_updates_to_nextcloud_via_ssh.sh
## version 0.1
## Check if updates are available from git repo



installedVersion=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "grep OC_VersionString /var/www/html/version.php | cut -d\"'\" -f2") )
sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "grep OC_VersionString /var/www/html/version.php" > /dev/null) 2>&1 )

availableVersion=$(git ls-remote --tags https://github.com/nextcloud/server.git | awk -F 'refs/tags/v' '{ print $2 }' | grep -v "\^" | sort -h | tail -n1)



if [ -z "$sshError" ] ; then ## if there's no error then continue

        if [ $(echo $installedVersion | sed 's/\.//g') -lt $(echo $availableVersion | sed 's/\.//g') ] ; then
                echo "WARNING - A new version of NextCloud is available. Please update from $installedVersion to $availableVersion"
                exit 1
        else
                echo "OK - NextCloud is up to date"
                exit 0
        fi


fi

        echo "Maybe a connection error - make sure you log into $(hostname) and run sudo su nagios and finally run ssh-copy-id before adding or editing a server to monitor - $sshError"
        exit 3
