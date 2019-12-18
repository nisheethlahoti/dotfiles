#!/bin/bash

# Run with cron on reboot
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
half_swap=$(($(free | tail -n +3 | awk '{sum+=$2}END{print sum}') / 2))

while true
do
	free=$(free | tail -n +2 | awk '{sum+=$4}END{print sum}')
	if [[ $free -lt $half_swap ]]
	then
		notify-send "Less than half of swap space free!"
		sleep 60
	else
		sleep 1
	fi
done
