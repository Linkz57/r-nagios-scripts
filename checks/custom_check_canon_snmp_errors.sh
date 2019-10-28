#!/bin/bash

## custom_check_canon_snmp_errors.sh
## version 1
##
## The goal is to check for a very spesific error on our dieing printer.
## snmpwalk is almost definitly the wrong way to do this, but it's super easy to grep through.
## $1 is the host address


if snmpwalk -v1 -c public $1 | grep "HOST-RESOURCES-MIB::hrPrinterDetectedErrorState.1 = Hex-STRING: 01" > /dev/null ; then
	echo "CRITICAL - I think this printer is broken and can't do anything useful. - $(snmpwalk -v1 -c public $1 | grep "HOST-RESOURCES-MIB::hrPrinterDetectedErrorState.1 = Hex-STRING:")"
	exit 2
else
	echo "OK - I think this printer is fine."
	exit 0
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

