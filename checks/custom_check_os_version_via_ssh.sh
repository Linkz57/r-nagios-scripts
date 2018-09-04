#!/bin/bash

## custom_check_os_version_via_ssh.sh
## version 0.1
##
## The goal is to simply list the OS version in Nagios so I can sort alphabetically and see who's wildly out of date.
## There is almost certainly a better place to retrieve, store, and view this information but I'm using Nagios regardless.
##
## $1 is the SSH username
## $2 is the host address

sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "uname" > /dev/null ) 2>&1)

if [ -z "$sshError" ] ; then
                echo "OK: $(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "echo \`uname -s\` \`uname -r\`")"
                exit 0
        else
                echo "CRITICAL - $sshError"
                exit 2
        fi
fi

## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
