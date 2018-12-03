#!/bin/bash

## custom_check_for_updates_using_apt_via_ssh.sh
## version 1
## $1 is ssh username
## $2 is ssh address
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_foo.sh to /usr/local/nagios/libexec
## chmod +x custom_check_foo.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_foo
##        command_line    $USER1$/custom_check_foo.sh $ARG1$ $ARG2$    ## ARG1 is ssh username, ARG2 is storage server address
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure bar is foo
##        check_command                   custom_check_foo!user!127.000.000.001
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
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong. Running journalctl -xeu nagios might show you where the error is.


sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "apt list --upgradable 2>/dev/null" | grep -v "Listing...\|All packages are up to date" | wc -l)




        if (( "$sshOutput" > 0 )) ; then
       	        echo "Pending updates: $sshOutput"
               	exit 1
        else
      	        echo "OK - Everything up to date"
               	exit 0
        fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
