#!/bin/bash

## Set a threshold here, under which a backup folder COULD be considered suspicious.
## If this script finds one such folder under this threshold, it will email you immediatly and stop.
## My threshold will be fourteen Mibabytes.
dangerZone=14M

myEmail= tyler dot francis at jelec dot com


printf "\n\n\n\n"


mount | grep "user@nas:/mnt/backups/Nagios/ on /home/mahuser/mounts/nas type fuse.sshfs" > /dev/null || sshfs user@nas:/mnt/backups/Nagios/ /home/mahusername/mounts/nas/

cd /home/nagios/mounts/nas/ || exit 1



## Quick check to make sure I'm not about to delete good old folders if bad new folders exist.
if du -bh --threshold=-$dangerZone . | grep / > /dev/null
        then
                printf "This is potentially terrible. I have found folders containing less than $dangerZone of backups, which you said might mean some backups have failed. I don't want to go deleting old backups if your new backups are bad. I'd recommend you check the following folders in user@nas:/mnt/backups/Nagios/ to make sure all of your Nagios backups are there, and that all of them are restorable:\n\n`du -bh --threshold=-$dangerZone . | grep /`\n\nYou said $dangerZone was small enough to merit concern on line 6 of ${0%/*}/cleanup_nagios_backups.sh on $(hostname)" | mail -s "Your Nagios backups located in user@nas:/mnt/backups/Nagios/ might be in danger" $myEmail
                exit 1
fi



echo "I deleted the following old Nagios backups"


## section header for email
echo "$cleanDir/$1/"
echo "--------------------------"
echo "Size    Date and Time"
echo "--------------------------"

ls -tp | grep / | tail -n +30 | sort | xargs -r -d '\n' du -bhc || exit 1


printf "\n\n\n\n"
echo "These are the problems I had, if any"
ls -tp | grep / | tail -n +30 | sort | xargs -r -d '\n' rm -r -- 2>&1



printf "\n\n\n\n"
echo "Don't worry, you still have the following undeleted backups residing in user@nas:/mnt/backups/Nagios/"
ls -t | grep -v "about this backup.txt" | sort


printf "\n\n\n\n"
echo "I know that's like thirty backups, but all together it only weighs $(du -bhs . | cut -f1) since they're a compressed collection of mostly text files"
echo "A drop in the bucket, especially since this bucket has a total capacity of$(df -h --output=size . | tail -n1)"
printf "\n\n\n\n"

cd ~
sleep 15
fusermount -u ~/mounts/nas/

printf "\n\n"
