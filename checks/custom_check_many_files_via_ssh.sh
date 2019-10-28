#!/bin/bash

## custom_check_many_files_via_ssh.sh
## version 1.0
## $1 is ssh username
## $2 is ssh address
## $3 is path to check in or under
## $4 is age in days that's considered too old. EG: 3 is 3 days.
## $5 is name of the thing you actually want to test, from zero to a billion subfolders under the path specified in $3. EG: home_folder.tar.gz
## $6 is size threshold, below which a backup isn't counted. EG: 7k means a backup less than 7 kilobytes (7168 bytes).
## Use different letters to indicate different units. Capital M for Mega and capital G for giga. Lowercase everything else.
##              `b'    for 512-byte blocks (this is the default if no suffix is used)
##              `c'    for bytes
##              `w'    for two-byte words
##              `k'    for Kilobytes (units of 1024 bytes)
##              `M'    for Megabytes (units of 1048576 bytes)
##              `G'    for Gigabytes (units of 1073741824 bytes)
##
##
## To use this yourself, (on Ubuntu 16.04.4 with Nagios Core 4.3.4)
## save custom_check_many_files_via_ssh.sh to /usr/local/nagios/libexec
## chmod +x custom_check_many_files_via_ssh.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_many_files_via_ssh
##        command_line    $USER1$/custom_check_many_files_via_ssh.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$    ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is backup path, ARG4 is acceptable age, after which emails will be sent. ARG5 is the name of the thing you actually want to test. EG: home_folder.tar.gz. ARG6 is the size threshold, below which a backup isn't counted. EG: 7k means a backup less than 7 kilobytes (7168 bytes).
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure a new version of bar exists somehere in this or subfolders, and is of a certain size.
##        check_command                   custom_check_many_files_via_ssh!user!127.000.000.001!/home/user/foo/bar!5!home_folder.tar.gz!2G
##;          arguments are seperated by "!"    command    ssh_user  ssh_address   object to check the modification age of          unacceptable age in days      name of actual backup to test      unaceptable size in given unit c,k,M, or G
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


os="$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "uname -o")"
plurality="$(if [ "$4" -gt "1" ] ; then echo "s" ; else echo "" ; fi )"

## -mtime -1 tested in FreeBSD 10.3 and Linux 4.13
sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "find $3 -type f -mtime -$4 -name '$5' -size +$6" )
sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "find $3 -type f -mtime -$4 -name '$5' -size +$6" > /dev/null 2>&1 ))

## Thanks to Adam Crume for the above line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable


if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking age
	if [[ "$os" = GNU/Linux ]] || [[ "$os" = FreeBSD ]] ; then  ## If the OS is Linux or FreeBSD, then I feel confidant that its FILE program works as predicted.
	        if echo "$sshOutput" | grep "$4" > /dev/null ; then
        	        echo "OK - The object was last modified within $4 day$plurality"
                	exit 0
	        else
        	        echo "CRITICAL - The object hasn't been modified within $4 day$plurality"
                	exit 2
	        fi
	else  ## If the OS is not Linux or FreeBSD, then who knows if its FILE program works the same.
		if echo "$sshOutput" | grep "$4" > /dev/null ; then
                        echo "OK - I think the object was last modified within $4 day$plurality, but maybe not. This script hasn't been fully tested on the platform you're SSHing into."
                        exit 0
                else
                        echo "CRITICAL - I think the object hasn't been modified within $4 day$plurality, but maybe it has. This script hasn't been fully tested on the platform you're SSHing into."
                        exit 2
                fi
	fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
