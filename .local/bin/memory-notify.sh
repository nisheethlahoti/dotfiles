#!/bin/bash

# Run with cron on reboot
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID/bus"
total=$(free | tail -n +2 | head -n 1 | awk '{print $2}')

while true
do
	used=$(free | tail -n +2 | awk '{sum+=$3}END{print sum}')
	if [[ $used -gt $total ]]
	then
		notify-send "Memory + swap usage exceeds RAM size!"
		sleep 60
	else
		sleep 1
	fi
done
