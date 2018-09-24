#!/bin/bash
now=$(\date +%Y-%m-%d_%H-%M)
env GZIP=-9 tar czf /tmp/nagios_backup_$now.tar.gz /usr/local/nagios/
cat /tmp/nagios_backup_$now.tar.gz | ssh user@nas "mkdir \"/mnt/backups/Nagios/$now\" && cat > \"/mnt/backups/Nagios/$now/nagios_backup_$now.tar.gz\""
rm /tmp/nagios_backup_*


echo "###############################################################"
echo "##  If tar had any problems, they would be listed above me.  ##"
echo "##    All else has been compressed and copied to our NAS.    ##"
echo "##  Here's a list of today's backups, according to the NAS:  ##"
echo "###############################################################"

printf "\n\n"

ssh user@nas "ls -lhR /mnt/backups/Nagios/$(\date +%Y-%m-%d)*" | awk '{ print $1 "    " $6 "    " $10 }' | sed 's/drwxrwxr-x+//g' | sed 's/xrwxr-x+//g' | sed 's/-rw//g'
#echo -e "\033[0;32m                    ⮤ that's you, ⮥"
#echo -e "\033[0;32m                      right there  "

DOW=$(\date +%u)
case $DOW in
        1 ) DOWtranslated="Monday" ;;
        2 ) DOWtranslated="Tuesday" ;;
        3 ) DOWtranslated="Wednesday" ;;
        4 ) DOWtranslated="Thursday" ;;
        5 ) DOWtranslated="Friday" ;;
        6 ) DOWtranslated="Saturday" ;;
        7 ) DOWtranslated="Sunday" ;;
esac


toilet "That's all for $DOWtranslated"

printf "\n\n\n"

#echo -e "\033[0m "
