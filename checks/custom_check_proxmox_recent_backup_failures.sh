#!/bin/bash

## custom_check_proxmox_recent_backup_failures.sh
## version 0.3
## $1 is ssh username
## $2 is ssh address
## $3 is path to check
## $4 is age in seconds that's considered too old. EG: 172800 is 3 days.
##
##
## To use this yourself, (on Ubuntu 16.04 with Nagios Core 4.3.1)
## save custom_check_proxmox_recent_backup_failures.sh to /usr/local/nagios/libexec
## chmod +x custom_check_proxmox_recent_backup_failures.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_proxmox_recent_backup_failures
##        command_line    $USER1$/custom_check_proxmox_recent_backup_failures.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$    ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is backup path, ARG4 is acceptable age, after which emails will be sent. 
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure bar is kept up to date
##        check_command                   custom_check_proxmox_recent_backup_failures!user!127.000.000.001!/home/user/foo/bar!172800
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


sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "grep -nir failed $3/*.log" | cut -d':' -f1 | sort -t- -k4 | tail -n1)
sshOutputDate=$(echo "$sshOutput" | awk -F'vzdump' '{print $2}' | awk -F'[-_.]' '{print $4 "/" $5 "/" $6 " " $7 ":" $8 ":" $9}')

sshError=$( (ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "ls $3" > /dev/null 2>&1 ))

## Thanks to Adam Crume for the above line, saving the error in a variable
## https://stackoverflow.com/questions/3130375/bash-script-store-stderr-in-a-variable



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking age
        if [ $(($(date +%s) - $(date -d "$sshOutputDate" +%s))) -lt "$4" ] ; then
                echo "CRITICAL - $(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "grep -i failed '$sshOutput'" | tail -n1 | cut -c -50)"
                exit 2
        else
                echo "OK - There hasn't been any recent backup failures"
                exit 0
        fi
else
        echo "Connection error - make sure you log into Nagios and run sudo su $(whoami) and finally run ssh-copy-id $1@$2 before adding or editing a service to monitor - $sshError"
        exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
