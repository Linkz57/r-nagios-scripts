#!/bin/bash

## custom_check_locked_proxvm_via_ssh.sh
## version 0.2
## $1 is ssh username
## $2 is ssh address
##
## There are a lot of good reasons for Proxmox to lock a Virtual Machine:
## performing backups, migrations, etc. When one of those fails in an ambiguous way,
## the VM will remain locked forever without human intervention.
## If the VM is locked while running, it'll stay running oblivious to its "locked" label.
## If you want to then perform a rolling update, for example, you can't migrate the locked VMs
## This script will watch a single Proxmox box.
## Tested with PVE version 5.4-13 and 6.0-9


{
        sshOutput=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pvesh get /nodes/localhost/qemu" 2> "/tmp/$0.error")
        sshError=$(cat < "/tmp/$0.error")
} 3<<EOF
EOF

## Thanks to Stéphane Chazelas for the above lines, saving the error in a variable
## https://unix.stackexchange.com/questions/430161/redirect-stderr-and-stdout-to-different-variables-without-temporary-files



if [ -z "$sshError" ] ; then  ## If there's no error, then continue checking
	sshOutputRaw=$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pvesh get /nodes/localhost/qemu  --output-format json-pretty")
	if [ -z "$sshOutputRaw" ]  ## No output (and no error from the previous check) means 
	then
		echo "OK - No VMs on this host - $sshOutput"
		exit 0
	fi


	sshOutputCut=$( echo "$sshOutputRaw" | grep '\"lock\" \: ' | cut -d':' -f2 | sort | tail -n1)
	if [ -z "$sshOutputCut" ]
	then
		echo "OK - no locked VMs"
		exit 0
	else
		## loop through Virtual Machines to find VMID, and lock status.
		for virtualMachines in $(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pvesh get /nodes/localhost/qemu --noborder 1 --noheader 1" | cut -d' ' -f3)
		do
			if [ -z "$(ssh "$1"@"$2" -o ConnectTimeout=10 -o BatchMode=yes "pvesh get /nodes/localhost/qemu/$virtualMachines/status/current  --output-format json-pretty" | grep '\"lock\" \: ' | cut -d':' -f2)" ]
			then
				true
			else
				echo "WARNING - VM $virtualMachines is locked. There are good reasons to lock a VM, but only for like 30 minutes max."
				exit 1
			fi
		done
	fi
else
	echo "Connection error, probably. - $sshError"
	exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
