#!/bin/bash

## mailbackups.sh
## version 1.1

if cd "~/scripts" ; then
	echo fine > /dev/null
else
        echo "could not cd to ~/scripts"
	exit 1
fi
#pwd -P


echo "I am three scripts running on $(hostname) in $(pwd -P)" >> backup.mail
echo "We are named backup_nagios.sh, cleanup_nagios_backups.sh, and mailbackups.sh" >> backup.mail
echo "To fiddle with us run:" >> backup.mail
echo "ssh -t someSSHaccount@$(hostname) \"sudo crontab -eu $(whoami)\"" >> backup.mail

cat backup.mail | grep -v "from member names\|/usr/local/nagios/var" | mail -s "Weekly results of daily Nagios backups" tyler dot francis at jelec dot com

\rm -f backup.mail
