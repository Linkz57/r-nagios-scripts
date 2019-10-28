#!/bin/bash

## custom_check_for_updates_to_nagios.sh
## version 1
## $1 is ssh username
## $2 is ssh address
##
## The goal is to ask the Nagios website if our current version is up to date

sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "/usr/local/nagios/bin/nagios --version" | head -n2 | tail -n1 | cut -d' ' -f3)


if curl "https://www.nagios.org/checkforupdates/?version=$sshOutput&product=nagioscore" | grep "Your installation of Nagios Core" | grep "$sshOutput" | awk -F'[<>]' '{print $9}' | grep "is up-to-date, so no upgrade is required." ; then
        exit 0
else
        echo "Warning - Nagios needs to be updated. This can be done automatically by running ssh -t toor@ansible \"ansible-playbook /etc/ansible/playbooks/updatenagios.yml --ask-vault-pass\" from any machine, even your own laptop."
        exit 1
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
