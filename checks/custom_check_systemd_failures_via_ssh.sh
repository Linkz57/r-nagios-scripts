#!/bin/bash

## custom_check_systemd_failures.sh
## version 1
##
## The goal is to make sure nothing is failing
## $1 is the ssh username
## $2 is the ssh address


sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "systemctl --failed --no-legend" > /dev/null) 2>&1 )

if [ -z "$sshError" ] ; then
	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "systemctl --failed --no-legend" | grep -v DESCRIPTION | cut -d' ' -f1)

	if [ -z "$sshOutput" ]; then
		echo "OK - All SystemD services that should be running, are."
		exit 0
	else
		echo CRITICAL - These services have failed: $sshOutput
		exit 2
	fi
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

