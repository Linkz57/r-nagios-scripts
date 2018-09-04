#!/bin/bash

## custom_check_read_only_filesystem_via_ssh.sh
## version 0.1
##
## The goal is to make sure the /tmp directory is always writable.
## In default setups, this will be a folder in the root partition,
## but even non-default setups where most of the disk is read only, the /tmp folder should be writable.
##
## $1 is the SSH username
## $2 is the host address

sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "touch /tmp/.CustomNagiosHealthCheck") 2>&1)

if [ -z "$sshError" ] ; then
                echo "OK - the /tmp directory is writable $sshError"
                exit 0
        else
                echo "CRITICAL - $sshError"
                exit 2
        fi
fi

## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
