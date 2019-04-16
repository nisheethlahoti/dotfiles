#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
used_swap=$(awk '{print $4}' /proc/swaps | tail -n 1)
free_swap=$(awk '{print $3}' /proc/swaps | tail -n 1)

if [[ $((used_swap * 2)) -gt $free_swap ]]
then
	notify-send "Half of swap space filled!"
fi
