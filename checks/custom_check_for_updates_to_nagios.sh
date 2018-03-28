#!/bin/bash

## custom_check_for_updates_to_nagios.sh
## version 1
##
## The goal is to ask the Nagios website if our current version is up to date



if curl "https://www.nagios.org/checkforupdates/?version=$(/usr/local/nagios/bin/nagios --version | head -n2 | tail -n1 | cut -d' ' -f3)&product=nagioscore" | grep "Your installation of Nagios Core" | grep "$(/usr/local/nagios/bin/nagios --version | head -n2 | tail -n1 | cut -d' ' -f3)" | awk -F'[<>]' '{print $9}' | grep "is up-to-date, so no upgrade is required." ; then
        exit 0
else
        echo "Warning - Nagios ought to be updated."
        exit 1
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3
