#!/bin/bash

## custom_check_update_needed_via_ssh.sh
## version 2.4
## Check if updates are needed. Throws warning on regular updates, and may later crit on security updates
## I just want everyone to know how clever I felt just remembering out of no where the syntax for Named Pipes.
## I think I committed it to memory so easily because it looks like the common diphthong <(^.^)>
## Version 1 and lower only supported Ubuntu
## Version 2 should support any OS with PackageKit    https://en.wikipedia.org/wiki/PackageKit#Back-ends
##
## $1 is ssh username
## $2 is ssh password



sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pkcon -p get-updates" > /dev/null 2>&1 ))

if [ -z "$sshError" ] ; then  ## If there's no error, then continue parsing for pending updates

	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pkcon -p get-updates | tail -n +\$(pkcon -p get-updates | grep -n Results | cut -d':' -f1)")
	noUpdates="$(printf "Results:\nThere are no updates available at this time.")"   ## This is printed only if there's no updates

	if echo "$sshOutput" | grep "There are no updates available at this time." > /dev/null ; then  ## No updates
#	if [ "$sshOutput" == "$noUpdates" ] ; then
		echo "OK - Everything up to date"
		exit 0
	else
		echo "$sshOutput" | grep -v "Please restart the computer to complete the update\|System restart required by"| cut -d ' ' -f1 | tail -n +2 | sort | uniq --count| cat <(echo Pending updates: ) - | tr -d '\n'
		printf " fixes"
		exit 1
	fi


else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi

## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

