battery_status=""
battery_status_color=""
last_battery_level=100
check_battery() {
	BATTERY_LOW_THRESHOLD=25
	BATTERY_VERY_LOW_THRESHOLD=10
	
	battery_status_info=`upower -i /org/freedesktop/UPower/devices/battery_BAT0`
	charge_status=`echo "$battery_status_info" | grep -E 'state:' | sed -r 's/.+\s([a-z\-]+)\s*/\1/g'`
	charge_percentage=`echo "$battery_status_info" | grep -E '\s*percentage:' | sed -r 's/\s*percentage:\s*([0-9]{1,3})\%/\1/g'`

	# if the battery is not charging,...
	if [ "$charge_status" = "discharging" ]; then
		# very low battery
		if [ "$charge_percentage" -le "$BATTERY_VERY_LOW_THRESHOLD" -a "$last_battery_level" -gt "$BATTERY_VERY_LOW_THRESHOLD" ]; then
			notify-send "VERY LOW BATTERY!! Charge NOW!!" --urgency critical
		# low battery
		elif [ "$charge_percentage" -le "$BATTERY_LOW_THRESHOLD" -a "$last_battery_level" -gt "$BATTERY_LOW_THRESHOLD" ]; then
			notify-send "Your battery is low! Charge soon!" --urgency normal
		fi
	# if the battery is charging and is fills up, inform the user
	elif [ "$charge_percentage" -eq 100 -a "$last_battery_level" -ne 100 ]; then
		notify-send "Your battery is fully charged!" --urgency low
	fi
	
	# update the last battery level
	last_battery_level="$charge_percentage"
}

test_wifi_speed() {
	TEMP_SPEED_TEST_RESULTS_FILE="/home/connor/.i3/.temp/Wi-Fi speed test results in progress.txt"
	if [ "$wifi_connected" ]; then
		if [ ! -f "$TEMP_SPEED_TEST_RESULTS_FILE" ]; then	# if the speed results are still being created, don't start a new speed test
			touch "$TEMP_SPEED_TEST_RESULTS_FILE"
			speedtest-cli > "$TEMP_SPEED_TEST_RESULTS_FILE"
			mv "$TEMP_SPEED_TEST_RESULTS_FILE" "$SPEED_TEST_RESULTS_FILE"
		fi
	fi
}

# TODO TEMP CMT: eats CPU!
# while : ; do
#	test_wifi_speed
# done &

while : ; do
	check_battery
	sleep 60
done
