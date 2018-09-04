#!/bin/bash

## custom_check_ceph_health_via_ssh.sh
## version 0.1
##
## The goal is to make sure a given CEPH cluster always reports as healthy, from each of the nodes
##
## $1 is the SSH username
## $2 is the host address

sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "ceph -s" > /dev/null ) 2>&1)

if [ -z "$sshError" ] ; then
        if echo "$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "ceph -s")" | grep HEALTH_OK > /dev/null ; then
                echo "OK - This node claims the CEPH cluster is healthy"
                exit 0
        else
                echo "CRITICAL - This node says the CEPH cluster is unhealthy - $(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "ceph -s" | grep health\:)"
                exit 2
        fi

else
        echo "UNKNOWN - probably a connection error - $sshError"
        exit 3
fi

## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
