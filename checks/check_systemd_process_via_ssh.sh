#!/bin/bash

## check_systemd_process_via_ssh.sh
## version 1.0
## $1 is ssh username
## $2 is ssh address
## $3 is the process name to check
##
##
## To use this yourself, (on Ubuntu with Nagios Core 4.3.1)
## save check_systemd_process_via_ssh.sh to /usr/local/nagios/libexec
## chmod +x check_systemd_process_via_ssh.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    check_systemd_process_via_ssh
##        command_line    $USER1$/check_systemd_process_via_ssh.sh $ARG1$ $ARG2$ $ARG3$   ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is the process name to check.
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure process bar is running
##        check_command                   check_systemd_process_via_ssh!user!127.000.000.001!mahprocess
##;          arguments are seperated by "!"    command                ssh_user  ssh_address   process name to check
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





## Thanks to Adam Crume for the following line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable
sshError=$( (ssh $1@$2 -o ConnectTimeout=10 -o BatchMode=yes "systemctl status $3" > /dev/null) 2>&1 )


if [ -z "$sshError" ] ; then
        if ssh -o ConnectTimeout=10 -o BatchMode=yes $1@$2 "systemctl is-active $3" > /dev/null ; then
                echo "OK - $3 is currently running at $2"
                exit 0
        else
                echo "CRITICAL - I don't think $3 is running at $2"
                exit 2
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su nagios and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

