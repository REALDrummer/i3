#!/bin/bash

MINIMUM_BRIGHTNESS=250
MAXIMUM_BRIGHTNESS=4882

BRIGHTNESS_CONTROLLER=/sys/class/backlight/intel_backlight/brightness

usage() {
	echo "Brightness levels can be $MINIMUM_BRIGHTNESS-$MAXIMUM_BRIGHTNESS (inclusive)."
	echo 'Usage: brightness-level [+-]# [--notify]'
	echo 'Options (where "#" represents a single-digit number):'
	echo '+# to increase the current brightness level by "#" levels.'
	echo '-# to decrease the current performance level by "#" levels.'
	echo '# to set the brightness level to this level.'
	echo 'The optional --notify flag will make notifications indicating that something went wrong if it did.'
	echo 'Note: the --notify flag must come AFTER the level designation!'
}

if [ "$#" -eq 0 ]; then
	echo -e "\x1B[1;31mYou must designate how to change the brightness level!\x1B[0m"
	usage
elif [[ "$1" =~ [+-]?[0-9] ]]; then
	current_brightness=`cat "$BRIGHTNESS_CONTROLLER"`
	
	# find the target brightness
	target_brightness=""
	first_char=${1:0:1}
	if [ "$first_char" = '+' -o "$first_char" = '-' ]; then
		if [ "$1" -eq 0 ]; then
			echo -e "\x1B[1;31mChanging the brightness level by 0 would do nothing!\x1B[0m"
			if [ "$#" -gt 1 -a "$2" = "--notify" ]; then
				notify-send "Changing the brightness level by 0 would do nothing!" --urgency normal
			fi
		fi
		number_value=$1
		target_brightness=$((current_brightness + number_value))
	else
		target_brightness=$1
	fi
	
	# verify the target brightness
	if [ "$target_brightness" -lt $MINIMUM_BRIGHTNESS -o "$target_brightness" -gt $MAXIMUM_BRIGHTNESS ]; then
		echo -e "\x1B[1;31m$target_brightness is not a valid brightness level! It must be between $MINIMUM_BRIGHTNESS and $MAXIMUM_BRIGHTNESS (inclusive)!\x1B[0m"
		usage
		# make error notifications
		if [ "$#" -gt 1 -a "$2" = "--notify" ]; then
			if [ "$first_char" = '-' ]; then
				notify-send "I can't go any darker!" --urgency normal --expire-time 3
			elif [ "$first_char" = '+' ]; then
				notify-send "I can't go any brighter!" --urgency normal --expire-time 3
			else
				notify-send "$target_brightness is not between $MINIMUM_BRIGHTNESS and $MAXIMUM_BRIGHTNESS!" --urgency normal
			fi
		fi
	else
		echo "$target_brightness" > "$BRIGHTNESS_CONTROLLER"
	fi
else
	echo -e "\x1B[1;31mYour argument is not in the proper format!\x1B[0m"
	usage
fi
