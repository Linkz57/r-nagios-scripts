#!/bin/bash

## custom_check_backup_ceph_via_ssh.sh
## version 1.0
## $1 is ssh username of CEPH node
## $2 is ssh address of CEPH node
## $3 is ssh username of some NAS
## $4 is ssh address of some NAS
## $5 is path on some NAS to save the backup to WITH NO TRAILING SLASH
##
##
## To use this yourself, (on Ubuntu 18.04 with Nagios Core 4.4.2)
## save custom_check_foo.sh to /usr/local/nagios/libexec
## chmod +x custom_check_foo.sh
## add following four lines to /usr/local/nagios/etc/objects/commands.cfg
## define command {
##        command_name    custom_check_foo
##        command_line    $USER1$/custom_check_foo.sh $ARG1$ $HOSTADDRESS$ $ARG2$ $ARG3$ $ARG4$ $ARG5$
##}
##
##
## then add the following seven lines to your host definition files, like /usr/local/nagios/etc/servers/mahserver.cfg
## define service {
##        use                             generic-service
##        host_name                       mahserver
##        service_description             CEPH CRUSH map backups
##        check_command                   custom_check_foo!cephuser!nasuser!127.000.000.001!/home/user/backups
##        check_interval                  259200
##;          arguments are seperated by "!"    command    ssh_user  ssh_address   object to check the modification age of          unacceptable age in seconds
##}
##
##
## That's all it takes to start using a new Nagios script.
##
## This script, however, requires automatic, password-less ssh access to CEPH and your backup storage server
## Use this guide to give your Nagios user that power:
## http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/
## It's only 2 steps. Remember to run these two steps AS THE USER that runs the Nagios check scripts. running "sudo su nagios" might do it.
##
## then run "sudo systemctl restart nagios" and you're done. Or you've spelled something wrong. Running journalctl -xeu nagios might show you where the error is.


if ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "ceph osd getcrushmap | crushtool -d -" | ssh "$3"@"$4" -o ConnectTimeout=10 -o BatchMode=yes "cat > \"$5\"/ceph_config_$(\date +%Y-%m-%d_%H-%M-%S).txt"
then
	echo "OK - I just backed up the CEPH CRUSH map from $2 to $4:$5 on $(date)"
	exit 0
else
	echo "CRITICAL - I, $(whoami)@$(hostname -A) failed to backup the CEPH CRUSH map from $2 to $4:$5 via SSH"
	exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
