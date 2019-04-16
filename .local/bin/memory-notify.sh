#!/bin/bash

# Run with cron on reboot
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
TOTAL_SWAP=$(awk '{print $3}' /proc/swaps | tail -n 1)
HALF_SWAP=$((TOTAL_SWAP / 2))

while true
do
	used_swap=$(awk '{print $4}' /proc/swaps | tail -n 1)
	if [[ $used_swap -gt $HALF_SWAP ]]
	then
		notify-send "Half of swap space filled!"
		sleep 60
	else
		sleep 1
	fi
done
