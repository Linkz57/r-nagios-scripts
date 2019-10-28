#!/bin/bash

## custom_check_foo.sh
## version 0.3
## $1 is string to grep for
## $2 is address
## $3 is success grep
## $4 is warning grep
## $5 is error grep
##
##
## The goal here is a more open ended check.
## currently I'm just using this to check various printers for their ink/toner levels
## each printer is gives different text on different SNMP... strings...
## here's an example of printer brand A:
## custom_check_snmp_any!43.18.1.1.8.1.3!everything_is_fine!" low "!out
##     command             SNMP string        success       warning   error
## Here's an example of printer brand B:
## custom_check_snmp_any!43.18.1.1.8.1.1!sleep!Low!Replace
##again: here's the command, SNMP string, success, warning, error - seperated by "!"


a=$(snmpwalk -v1 -c public $2 | grep -oP "(?<=$1).*" )

if echo "$a" | grep $3 ; then exit 0 ; fi
if echo "$a" | grep $4 ; then exit 1 ; fi
if echo "$a" | grep $5 ; then exit 2 ; fi

echo "Unknown status. Probably fine"
exit 0
