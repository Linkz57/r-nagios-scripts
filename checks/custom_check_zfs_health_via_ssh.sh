#!/bin/bash

## custom_check_zfs_health_via_ssh.sh
## version 1
##
## The goal is to make sure all pools are physically healthy. This will not test size thresholds.
## $1 is the ssh username
## $2 is the ssh address


sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "zpool status" > /dev/null) 2>&1 )

if [ -z "$sshError" ] ; then
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "zpool status -x" )

        if echo $sshOutput | grep "all pools are healthy" > /dev/null; then
                echo "OK - All ZFS pools are healthy"
                exit 0
        else
                echo "CRITICAL - pool$(echo "$sshOutput" | grep pool\: | cut -d':' -f2) - $(echo "$sshOutput" | grep status\: )"
                exit 2
        fi
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
