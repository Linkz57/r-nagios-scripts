#!/bin/bash

## check_apcupsd.sh
## version 1.0
## This is my first foray into writing a "Nagios plugin".
## I can't figure out how to install other people's plugins, but writing my own seems doable.


sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "apcaccess")


## Thanks to Adam Crume for the following line, saving the error to a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "apcaccess" > /dev/null) 2>&1 )


if [ -z "$sshError" ] ; then
	if echo "$sshOutput" | grep "STATUS   : ONLINE" > /dev/null ; then 
		echo "OK - this monitored machine can see its UPS - $(echo "$sshOutput" | grep "STATUS")"
		exit 0
	else
		echo "CRITICAL - this monitored machine can not see its UPS - $(echo "$sshOutput" | grep "STATUS")"
		exit 2
	fi
else
	echo Connection Error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id before adding or editing a server to monitor - $sshError
	exit 1
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
