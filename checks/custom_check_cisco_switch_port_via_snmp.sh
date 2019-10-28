#!/bin/bash

## custom_check_cisco_switch_port_via_snmp.sh
## version 1
##
## The built-in Nagios SNMP plugin thinks a failed port is A-OK, so I wrote this using the same backend.
## The goal is to make sure all ports are in "fullDuplex", AKA active and working.
## $1 is IP address of target
## $2 is protocol version, like 2c
## $3 is community string
## $4 is two digit port number to check (with leading zero if necessary)


if snmpget $1 -v $2 -c $3 iso.3.6.1.2.1.10.7.2.1.19.101$4 | grep " = INTEGER: 3" > /dev/null; then
	echo "OK - Port $4 is in Full Duplex mode"
	exit 0
else
	echo "CRITICAL - Port $4 is not in Full Duplex mode - $(snmpget $1 -v $2 -c $3 iso.3.6.1.2.1.10.7.2.1.19.101$4)"
	exit 2
fi


## If we've gotten this far, then I don't know what the problem could be.
## I'll tell Nagios to report an "unknown" status to the humans.
exit 3

