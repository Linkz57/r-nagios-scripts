#!/bin/bash

## custom_check_temperature_via_ssh.sh
## version 1.1
## $1 is ssh username
## $2 is ssh address
## $3 is max Celsius Temperature anything can be at, as returned by "lm-sensors", written as an intiger
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_foo.sh to /usr/local/nagios/libexec
## chmod +x custom_check_foo.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_foo
##        command_line    $USER1$/custom_check_foo.sh $ARG1$ $ARG2$ $ARG3$    ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is max temp
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure bar is foo
##        check_command                   custom_check_foo!user!127.000.000.001!45
##;          arguments are seperated by "!"    command    ssh_user  ssh_address   object to check the modification age of          unacceptable age in seconds
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


{
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "sensors -u" 2> /tmp/$0.error)
        sshError=$(cat</tmp/$0.error)
} 3<<EOF
EOF

## Thanks to Stéphane Chazelas for the above lines, saving the error in a variable
## https://unix.stackexchange.com/questions/430161/redirect-stderr-and-stdout-to-different-variables-without-temporary-files



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking
	sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "sensors -u" | grep -E 'temp.*input: ' | awk -F'[ .]' '{print $4}' | sort -r | head -n1)

        if [ "$3" -lt "$sshOutput" ] ; then
       	        echo "CRITICAL - something is hotter than $3°C - I think it's the $(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "sensors | grep $sshOutput" | cut -d':' -f1 | head -n1) at $sshOutput°C"
               	exit 2
        else
      	        echo "OK - eveything's cool, nothing above $3°C"
               	exit 0
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 3
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
