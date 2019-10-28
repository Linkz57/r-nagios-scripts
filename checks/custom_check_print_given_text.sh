#!/bin/bash

## Nagios should not be used for such static information, but that's what I want to do here. So I did.

## repeat what you were told to say by the config file
echo "$1"

## give the exit code you were told by the config file
exit "$2"
