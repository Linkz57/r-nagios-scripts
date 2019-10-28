#!/bin/bash

## custom_check_uncommitted_git_changes.sh
## version 1.1
## $1 is ssh username
## $2 is ssh address
## $3 is path to check
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_foo.sh to /usr/local/nagios/libexec
## chmod +x custom_check_foo.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_foo
##        command_line    $USER1$/custom_check_foo.sh $ARG1$ $ARG2$ $ARG3$   ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is the repo path
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure bar is foo
##        check_command                   custom_check_foo!user!127.000.000.001!/home/user/foo/bar
##;          arguments are seperated by "!"    command    ssh_user  ssh_address   repo to check
##}
##
##
## That's all it takes to start using a new Nagios script.
##
## This script, however, requires automatic, password-less ssh access to the target machine
## or wherever you're storing the file/folder you want to monitor.
## Use this guide to give your Nagios user that power:
## http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
## It's only 2 steps. Remember to run these two steps AS THE USER that runs the Nagios check scripts. running "sudo su nagios" might do it.
##
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong. Running journalctl -xeu nagios might show you where the error is.


sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cd $3 && git status" > /dev/null 2>&1 ))

## Thanks to Adam Crume for the above line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking for pending commits
	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cd $3 && git status")

	if echo "$sshOutput" | grep "nothing to commit, working" > /dev/null ; then
		sshCompareRemote=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "cd $3 && git fetch 2> /dev/null && git diff master FETCH_HEAD --name-only")

		if [ -z "$sshCompareRemote" ] ; then
	       	        echo "OK - All tracked files have been committed"
        	       	exit 0
		else
			echo WARNING - These files were committed but not backed up to remote git server: $sshCompareRemote
			exit 1
		fi
        else
      	        cat <(echo "$sshOutput" | grep "Changes to be committed\|Changes not staged for commit\|new file\|modified\:\|Untracked files") <(if echo "$sshOutput" | grep -n "Untracked files" > /dev/null ; then echo $sshOutput | tail -n +$(echo $(echo "$sshOutput" | grep -n "Untracked files" | cut -d':' -f1) + 3 | bc) | grep -v "no changes added to commit " ; fi) | tr -d '\n'
               	exit 1
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
