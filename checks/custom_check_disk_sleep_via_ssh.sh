#!/bin/bash


## custom_check_disk_sleep_via_ssh.sh
## version 1.1
## $1 is ssh username
## $2 is ssh address
##
## To use this yourself, (on Ubuntu 16.04.4 with Nagios Core 4.3.4)
## save custom_check_many_files_via_ssh.sh to /usr/local/nagios/libexec
## chmod +x custom_check_disk_sleep_via_ssh.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_disk_sleep_via_ssh
##        command_line    $USER1$/custom_check_disk_sleep_via_ssh.sh $ARG1$ $HOSTADDRESS$   ## ARG1 is ssh username
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Unsaved Configs
##        check_command                   custom_check_disk_sleep_via_ssh!user
##;          arguments are seperated by "!"    command    ssh_user  ssh_address
##}
##
##
## That's all it takes to start using a new Nagios script.
##
## This script, however, requires automatic, password-less ssh access to your NAS
## or wherever you're storing the file/folder you want to monitor.
## Use this guide to give your Nagios user that power:
## http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
## It's only 2 steps. Remember to run these two steps AS THE USER that runs the Nagios check scripts. running "sudo su nagios" might do it.
##
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong. Running journalctl -xe might show you where the error is.


sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "vmstat" | awk '(NR==2){for(i=1;i<=NF;i++)if($i=="wa"){getline; print $i}}')
sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "vmstat" | grep wa > /dev/null 2>&1 ))

## Thanks to Michalrajer for the above line, parsing vmstat
## https://stackoverflow.com/questions/7346675/efficient-way-to-parse-vmstat-output

## Thanks to Adam Crume for the above line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable


if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking
if [ -z "$sshOutput" ] ; then  ## If vmstat and AWK returned a null value, try just running vmstat alone
	ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "vmstat"
	exit 1
fi

	if [ "$sshOutput" -lt 10 ]; then
		echo "OK - Only waiting $sshOutput TimeUnits on reading/writing to disks/network"
               	exit 0
       	else
		if [ "$sshOutput" -gt 30 ]; then
			echo "CRITICAL - Currently waiting $sshOutput TimeUnits on reading/writing to disks/network. It should be zero."
        	       	exit 2
		else
			echo "WARNING - Currently waiting $sshOutput TimeUnits on reading/writing to disks/network. Scrutinize your pipeline before this becomes a problem."
			exit 1
		fi
       	fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
