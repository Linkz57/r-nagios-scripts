#!/bin/bash

## custom_check_memory_percentage_via_ssh.sh
## version 1.2
##
## $1 is ssh username
## $2 is ssh address
## $3 is the memory you want to check for (either Swap or Mem)


## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "free" > /dev/null) 2>&1 )
sshOutput=$(ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "free" | grep $3)


## make sure we don't divide by zero, in case you have no swap configured
if [ "$( echo "$sshOutput" | awk -F' ' '{ print $2 }')" == "0" ] ; then
	if [ "$3" == "Swap" ] ; then
		echo "WARNING - No swap is configured. It's generally good advice to have a swap file or partition"
		exit 1
	else
		echo "CRITICAL - I think you have no RAM installed. Either I messed up, or your system is borked."
		exit 2
	fi
fi

percentage=$(echo "$sshOutput" | awk '{ percent = $3 / $2 * 100 ; split(percent,truncate,".") ; print truncate[1]}')



if [ -z "$sshError" ] ; then ## if there's no error then continue
	if [ "$3" == "Mem" ] ; then ## if you're measuring RAM then use these big numbers
	        if (("$percentage" < "85")) ; then
        	        echo "OK - consuming $percentage percent of RAM"
                	exit 0
	        elif (("$percentage" < "95")) ; then
        	        echo "WARNING - consuming $percentage percent of RAM"
                	exit 1
		else
			echo "CRITICAL - consuming $percentage percent of RAM"
			exit 2
	        fi

	else ## if you're measuring Swap then use these small numbers
		if (("$percentage" < "20")) ; then
			echo "OK - consuming $percentage percent of $3"
			exit 0
		elif (("$percentage" < "40")) ; then
			echo "WARNING - consuming $percentage percent of $3"
			exit 1
		else
			echo "CRITICAL - consuming $percentage percent of $3"
			exit 2
                fi
	fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 3
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

