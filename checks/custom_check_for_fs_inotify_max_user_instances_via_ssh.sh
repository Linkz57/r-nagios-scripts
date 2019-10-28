#!/bin/bash

## custom_check_for_fs_inotify_max_user_instances_via_ssh.sh
## version 1.0
## $1 is ssh username
## $2 is ssh address
## $3 is path to check (syslog is expected)
## $4 is age in seconds that's considered too recent. EG: 172800 is 3 days.
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.5)
## save custom_check_for_fs_inotify_max_user_instances_via_ssh.sh to /usr/local/nagios/libexec
## chmod +x custom_check_for_fs_inotify_max_user_instances_via_ssh.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_for_fs_inotify_max_user_instances_via_ssh
##        command_line    $USER1$/custom_check_for_fs_inotify_max_user_instances_via_ssh.sh $ARG1$ $ARG2$ $ARG3$ $ARG4$    ## ARG1 is ssh username, ARG2 is storage server address, ARG3 is path to syslog, ARG4 is age in seconds that's considered too recent.
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             Make sure no soft kernel limits have been hit recently
##        check_command                   custom_check_for_fs_inotify_max_user_instances_via_ssh!user!127.000.000.001!/var/log/syslog!172800
##;          arguments are seperated by "!"           command                                ssh_user   ssh_address   path_to_syslog       unacceptable age in seconds
##}
##
##
## That's all it takes to start using a new Nagios script.
##
## This script, however, requires automatic, password-less ssh access to your rsyslog server,
## or to every one of your individual machines
## Use this guide to give your Nagios user that power:
## http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
## It's only 2 steps. Remember to run these two steps AS THE USER that runs the Nagios check scripts.
## Running "sudo su nagios" might do it.
##
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong,
## running journalctl -xeu nagios might show you where the error is.


{
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "stat $3" 2> /tmp/$0.error)
        sshError=$(cat</tmp/$0.error)
} 3<<EOF
EOF

## Thanks to Stéphane Chazelas for the above lines, saving the error in a variable
## https://unix.stackexchange.com/questions/430161/redirect-stderr-and-stdout-to-different-variables-without-temporary-files



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking age
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "grep 'Too many open files' $3" | awk -F' ' '{print $1 " " $2 " " $3 " " $4}' | tail -n1)
        past=$(date -d "$( echo "$sshOutput" | cut -d' ' -f1-3)" +%s)
        acceptableAge=$(echo $(date +%s) - $4 | bc)
        if [ "$past" -gt "$acceptableAge" ] ; then
                echo "CRITICAL - on $sshOutput hit a soft kernel limit called fs.inotify.max_user_instances - either reduce its workload or increase the limit"
                exit 2
        else
                echo "OK - no issues found with any machine keeping its syslogs at $2:$3"
                exit 0
        fi
else
        echo "Connection error - $sshError"
        exit 3
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
