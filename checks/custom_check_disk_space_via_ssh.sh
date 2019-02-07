#!/bin/bash

## custom_check_disk_space_via_ssh.sh
## version 2.1
## $1 is ssh username
## $2 is ssh address
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_disk_space_via_ssh.sh to /usr/local/nagios/libexec
## chmod +x custom_check_disk_space_via_ssh.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_disk_space_via_ssh
##        command_line    $USER1$/custom_check_disk_space_via_ssh.sh $ARG1$ $ARG2$  ## ARG1 is ssh username, ARG2 is server address
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Disk space
##        check_command                   custom_check_disk_space_via_ssh!user!127.000.000.001
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


sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "df -H" > /dev/null 2>&1 ))

## Thanks to Adam Crume for the above line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable


if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking free space
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "df -H" | grep -vE '^Filesystem|tmpfs|cdrom|loop|devfs|fdescfs' | awk '{ print $5 " " $1 }' | sort -h | tail -n1)
        biggestnumber=$(echo "$sshOutput" | cut -d'%' -f1 )
        if [ $biggestnumber -ge 90 ]; then
                echo "CRITICAL - Running out of space - $sshOutput"
                exit 2
        elif [ $biggestnumber -ge 80 ]; then
                echo "WARNING - Running low on space - $sshOutput"
                exit 1
        elif [ $biggestnumber -le 81 ]; then
                echo "OK - you're good on free space. Here's the fullest parition - $sshOutput"
                exit 0
        else
                echo "UNKNOWN - I have no idea what's going on - $sshError - $sshOutput"
                exit 3
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 3
fi

exit 3
