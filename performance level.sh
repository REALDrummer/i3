#!/bin/bash

usage() {
	echo 'Performance levels can be 0-8 (inclusive).'
	echo 'Usage: performance-level [+-]# [--notify]'
	echo 'Options (where "#" represents a single-digit number):'
	echo '+# to increase the current performance level by "#" levels.'
	echo '-# to decrease the current performance level by "#" levels.'
	echo '# to set the performance level to this level.'
	echo 'The optional --notify flag will make notifications indicating that something went wrong if it did.'
	echo 'Note: the --notify flag must come AFTER the level designation!'
}

if [ "$#" -eq 0 ]; then
	echo -e "\x1B[1;31mYou must designate how to change the performance level!\x1B[0m"
	usage
elif [[ "$1" =~ [+-]?[0-9] ]]; then
	current_performance=`cpufreq-info | grep '"performance"' | wc -l`
	
	# find the target performance
	target_performance=""
	first_char=${1:0:1}
	if [ "$first_char" = '+' -o "$first_char" = '-' ]; then
		if [ "$1" -eq 0 ]; then
			echo -e "\x1B[1;31mChanging the performance level by 0 would do nothing!\x1B[0m"
			if [ "$#" -gt 1 -a "$2" = "--notify" ]; then
				notify-send "Changing the performance level by 0 would do nothing!"
			fi
		fi
		number_value=$1
		target_performance=$((current_performance + number_value))
	else
		target_performance=$1
	fi
	
	# verify the target performance
	if [ "$target_performance" -lt 0 -o "$target_performance" -gt 8 ]; then
		echo -e "\x1B[1;31m$target_performance is not a valid performance level! It must be between 0 and 8 (inclusive)!\x1B[0m"
		usage
		# make error notifications
		if [ "$#" -gt 1 -a "$2" = "--notify" ]; then
			if [ "$first_char" = '-' ]; then
				notify-send "I can't go any lower on performance!"
			elif [ "$first_char" = '+' ]; then
				notify-send "I'm givin' 'er all she's got, Captain!"
			else
				notify-send "$target_performance is not between 0 and 8!"
			fi
		fi
	elif [ "$target_performance" -lt "$current_performance" ]; then
		for i in `seq "$target_performance" $(($current_performance - 1))`; do
			cpufreq-selector -g powersave -c "$i"
		done
	else
		for i in `seq "$current_performance" $(($target_performance - 1))`; do
			cpufreq-selector -g performance -c "$i"
		done
	fi
else
	echo -e "\x1B[1;31mYour argument is not in the proper format!\x1B[0m"
	usage
fi
