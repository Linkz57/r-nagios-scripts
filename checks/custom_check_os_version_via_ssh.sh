#!/bin/bash

## custom_check_os_version_via_ssh.sh
## version 1.3
## $1 is ssh username
## $2 is ssh address
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_foo.sh to /usr/local/nagios/libexec
## chmod +x custom_check_foo.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_os_version_via_ssh
##        command_line    $USER1$/custom_check_os_version_via_ssh.sh $ARG1$ $HOSTADDRESS$    ## ARG1 is ssh username, ARG2 is the server address
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure bar is foo
##        check_command                   custom_check_foo!user
##;          arguments are seperated by "!"    command    ssh_user
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
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong. Running journalctl -xeu nagios might show you where the error is.


#sshError=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /etc/*release" > /dev/null 2>&1 )

{
	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /etc/*release" 2> /dev/fd/3)
	sshError=$(cat<&3)
} 3<<EOF
EOF

## Thanks to Stéphane Chazelas for the above line, saving the error in a variable
## https://unix.stackexchange.com/questions/430161/redirect-stderr-and-stdout-to-different-variables-without-temporary-files



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking age
	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /etc/*release")
	if echo "$sshOutput" | grep release ; then
		exit 0
	elif echo "$sshOutput" | grep DISTRIB_DESCRIPTION > /dev/null ; then
		echo "$sshOutput" | grep DISTRIB_DESCRIPTION | cut -d'"' -f2
		exit 0
	else
		ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cat /proc/version" | awk -F'[()]' '{print $5}'
		exit 0
	fi
else
	if ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "echo \`uname -s\` \`uname -r\`" ; then
		exit 0
	else
	        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        	exit 3
	fi
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
