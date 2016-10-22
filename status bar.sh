#!/bin/bash

format_entry() {
	if [ "$#" -eq 2 ]; then
		echo '{"color":"'"$2"'","full_text":"'"$1"'"}'
	elif [ "$#" -eq 1 ]; then
		echo '{"full_text":"'"$1"'"}'
	fi
}

gpu_status=""
gpu_status_color=""
stat_gpu() {
	GPU_MODERATELY_HIGH_THRESHOLD=20
	GPU_HIGH_THRESHOLD=45
	GPU_VERY_HIGH_THRESHOLD=85
	
	# acquire the current GPU usage
	gpu_usage=`nvidia-settings -q GPUUtilization | grep --color=never "Attribute" | sed -r 's/.+\sgraphics.([0-9]+),.+$/\1/g'`
	
	# determine the color fo the GPU usage
	if [ "$gpu_usage" -ge "$GPU_VERY_HIGH_THRESHOLD" ]; then
		gpu_status_color="#FF0000"	# color = red
	elif [ "$gpu_usage" -ge "$GPU_HIGH_THRESHOLD" ]; then
		gpu_status_color="#FFFF00"	# color = yellow
	elif [ "$gpu_usage" -ge "$GPU_MODERATELY_HIGH_THRESHOLD" ]; then
		gpu_status_color="#FFFF99"	# color = pale yellow
	else
		gpu_status_color="#FFFFFF"	# color = plain
	fi
	
	gpu_status="$gpu_usage%🄶🄿🅄"
}

cpu_status=""
cpu_status_color=""
stat_cpu() {
	OVERALL_CPU_MODERATELY_HIGH_THRESHOLD=10
	OVERALL_CPU_HIGH_THRESHOLD=25
	OVERALL_CPU_VERY_HIGH_THRESHOLD=60
	
	# the two values below are commented out because they are accounted for in `grep` calls
	# PROCESS_CPU_HIGH_THRESHOLD=5
	# PROCESS_CPU_VERY_HIGH_THRESHOLD=10
	
	# filter out the high and very high CPU using processes
	# TODO: replace ps calls with top -bn1 calls
	high_cpu_process_usages=`ps aux | grep -E '^(\S+\s+){2}([5-9]|[0-9]{2,})\.' | sort -rk 3,1 | head -n 3 | sed -r 's/^\w+\+?\s+[0-9]+\s+([0-9]+(\.[0-9]+)?).+/\1/g'`
	high_cpu_process_name_list=`ps aux | grep -E '^(\S+\s+){2}([5-9]|[0-9]{2}|[0-9]{3})\.' | sort -rk 3,1 | head -n 3 | sed -r 's,^(\S+\s+){10}/?((\S+|"[^"]"|'"'"'[^'"'"']'"'"')/)*(\S+)\s+.+,\4,g' | uniq`
	very_high_cpu_process_name_list=`ps aux | grep -E '^(\S+\s+){2}([0-9]{2}|[0-9]{3})\.' | sort -rk 3,1 | head -n 3 | sed -r 's,^(\S+\s+){10}/?((\S+|"[^"]"|'"'"'[^'"'"']'"'"')/)*(\S+).+,\4,g' | uniq`
	
	# add the CPU usage of all the high CPU processes together to get an overall usage statistic
	cpu_usage=0
	for high_cpu_process_usage in $high_cpu_process_usages; do
		cpu_usage=`bc <<< "$cpu_usage"' + '"$high_cpu_process_usage"`
	done
	
	# concatenate the high or very high CPU process names
	high_cpu_process_names=""
	for high_cpu_process_name in $high_cpu_process_name_list; do
		if [ "$high_cpu_process_names" ]; then
			high_cpu_process_names="$high_cpu_process_names, $high_cpu_process_name"
		else
			high_cpu_process_names="$high_cpu_process_name"
		fi
	done
	
	very_high_cpu_process_names=""
	for very_high_cpu_process_name in $very_high_cpu_process_name_list; do
		if [ "$very_high_cpu_process_names" ]; then
			very_high_cpu_process_names="$very_high_cpu_process_names, $very_high_cpu_process_name"
		else
			very_high_cpu_process_names="$very_high_cpu_process_name"
		fi
	done
	
	# determine the color of the CPU usage region
	if [ `echo "$cpu_usage"' > '"$OVERALL_CPU_VERY_HIGH_THRESHOLD" | bc` -eq 1 ]; then
		cpu_status_color="#FF0000"	# color = red
	elif [ `echo "$cpu_usage"' > '"$OVERALL_CPU_HIGH_THRESHOLD" | bc` -eq 1 ]; then
		cpu_status_color="#FFFF00"	# color = yellow
	elif [ `echo "$cpu_usage"' > '"$OVERALL_CPU_MODERATELY_HIGH_THRESHOLD" | bc` -eq 1 ]; then
		cpu_status_color="#FFFF99"	# color = pale yellow
	else
		cpu_status_color="#FFFFFF"	# color = plain
	fi
	
	# determine whether the high or very high CPU processes should be listed
	listed_cpu_processes=""
	if [ `bc <<< "$cpu_usage"' > '"$OVERALL_CPU_VERY_HIGH_THRESHOLD"` -eq 1 -a "$very_high_cpu_processes" ]; then
		listed_cpu_processes=" $very_high_cpu_process_names"
	elif [ `bc <<< "$cpu_usage"' > '"$OVERALL_CPU_HIGH_THRESHOLD"` -eq 1 -a "$high_cpu_processes" ]; then
		listed_cpu_processes=" $high_cpu_process_names"
	fi
	
	# assemble the CPU status text
	cpu_status="$cpu_usage%🄲🄿🅄$listed_cpu_processes"
}

battery_status=""
battery_status_color=""
last_battery_level=100
stat_battery() {
	BATTERY_LOW_THRESHOLD=25
	BATTERY_VERY_LOW_THRESHOLD=10
	
	battery_status_symbol=""
	battery_status_info=`upower -i /org/freedesktop/UPower/devices/battery_BAT0`
	charge_status=`echo "$battery_status_info" | grep -E 'state:' | sed -r 's/.+\s([a-z\-]+)\s*/\1/g'`
	charge_percentage=`echo "$battery_status_info" | grep -E '\s*percentage:' | sed -r 's/\s*percentage:\s*([0-9]{1,3})\%/\1/g'`
	charge_discharge_time=`echo "$battery_status_info" | grep -E 'time to (full|empty):' | sed -r 's/[^0-9]+([0-9]+\.[0-9]*)?\s*(\w+)\s*/\1 \2/g'`

	# if the battery is not charging,...
	battery_status_symbol="±"
	if [ "$charge_status" = "discharging" ]; then
		# very low battery
		if [ "$charge_percentage" -le "$BATTERY_VERY_LOW_THRESHOLD" ]; then
			battery_status_color="#FF0000"	# color = red
		# low battery
		elif [ "$charge_percentage" -le "$BATTERY_LOW_THRESHOLD" ]; then
			battery_status_color="#FFFF00"	# color = yellow
		else 
			battery_status_color="#FFFFFF"	# color = plain
		fi
		
		# update the last battery level
		last_battery_level="$charge_percentage"
		
	# if the battery is charging...
	else
		# full battery
		if [ "`grep -F "battery-full" <<< "$battery_status_info"`" ]; then
			battery_status_color="#00FF00"	# color = green
			battery_status_symbol="⚡➾✅"
		# regular charging battery state
		else
			battery_status_color="#AAFFAA"	# color = pale green
			battery_status_symbol="⚡➾±"
		fi
		
		# consider a charging battery full for the purposes of low battery notifications
		last_battery_level=100
	fi
	
	if [ "$charge_status" = "fully-charged" -o "$charge_discharge_time" = "" ]; then
		battery_status="$battery_status_symbol $charge_percentage%"
	else
		battery_status="$battery_status_symbol $charge_percentage% (~$charge_discharge_time)"
	fi
}

volume_status=""
volume_status_color=""
stat_volume() {
	VERY_HIGH_VOLUME_THRESHOLD=90
	HIGH_VOLUME_THRESHOLD=75
	LOW_VOLUME_THRESHOLD=25
	
	# get the volume
	# TODO FIX: the two `grep`s down below might find the wrong mute; I'm aiming for the second sink's results
	volume=`pactl list sinks | grep -E '^\s*Volume' | head -n 1 | sed -r 's/.+\s+([0-9]{1,3})%.+/\1/g'`
	muted=`pactl list sinks | grep "Mute: yes" | head -n 1`
	headphones=`pactl list sinks | grep -E '(Headphones|Line Out) \(priority:\s*[0-9]+,\s*available' | head -n 1`
	
	if [ "$muted" ]; then
		volume_status_symbol="𝄽"
		volume_status_color="#999999"	# color = gray
	else
		volume_status_color="#FFFFFF"	# color = plain
		if [ "$volume" -ge "$HIGH_VOLUME_THRESHOLD" ]; then
			volume_status_symbol="♫♪"
			if [ "$volume" -ge "$VERY_HIGH_VOLUME_THRESHOLD" ]; then
				volume_status_color="#FFFF00"	# color = yellow
			fi
		elif [ "$volume" -le "$LOW_VOLUME_THRESHOLD" ]; then
			volume_status_symbol="♪"
		else
			volume_status_symbol="♫"
		fi
	fi
	
	volume_status="$volume_status_symbol $volume%"
	if [ "$headphones" ]; then
		volume_status="⨴ $volume_status ⨵"
	fi
}

SPEED_TEST_RESULTS_FILE="/home/connor/.i3/.temp/Wi-Fi speed test results.txt"
wifi_status=""
wifi_status_color=""
wifi_connected=""
download_speed="???"
upload_speed="???"
loading_ellipsis=""
stat_wifi() {
	# TODO: add Bluetooth (use hcitool) marked "🇧🇹"
	wifi_info=`iwconfig wlp2s0`
	is_up=`grep -E 'Tx-Power=[0-9]' <<< "$wifi_info"`
	if [ "$is_up" ]; then
		wifi_connected=`grep -F 'ESSID:"' <<< "$wifi_info"`
		if [ "$wifi_connected" ]; then
			# if the speed test results are available, update them in our variables
			#if [ -e "$SPEED_TEST_RESULTS_FILE" ]; then
			#	download_speed=`cat "$SPEED_TEST_RESULTS_FILE" | grep 'Download: ' | sed -r 's/[^0-9]+([0-9]+\.[0-9]+).+/\1/g'`
			#	upload_speed=`cat "$SPEED_TEST_RESULTS_FILE" | grep 'Upload: ' | sed -r 's/[^0-9]+([0-9]+\.[0-9]+).+/\1/g'`
			#	rm "$SPEED_TEST_RESULTS_FILE"
			#else
			download_speed="???"
			upload_speed="???"
			#fi
			#wifi_status="⇊ $download_speed""Mb/s ⇈ $upload_speed""Mb/s"
			loading_ellipsis=""
			# TODO: colors depending on network speed
			wifi_status_color="#FFFFFF"
			
			# find the name of the network we're connected to
			connected_network=`grep -F 'ESSID' <<< "$wifi_info" | sed -r 's/^.+ESSID:"([^"]+)".+$/\1/g'`
			
			# find the signal strength and dislay it in bars
			HIGH_SIGNAL_STRENGTH_THRESHOLD=60
			LOW_SIGNAL_STRENGTH_THRESHOLD=40
			signal_strength=`grep -F 'Link Quality' <<< "$wifi_info" | sed -r 's,^.+Link Quality=([0-9]+)/70.+$,\1,g'`
			signal_bars=""
			if [ "$signal_strength" -ge "$HIGH_SIGNAL_STRENGTH_THRESHOLD" ]; then
				signal_bars="▂▄▇"
			elif [ "$signal_strength" -le "$LOW_SIGNAL_STRENGTH_THRESHOLD" ]; then
				signal_bars="▂"
			else
				signal_bars="▂▄"
			fi
			
			wifi_status="🇼 $signal_bars $connected_network"
		else
			download_speed="???"
			upload_speed="???"
			wifi_status="🇼$loading_ellipsis"
			if [ "$loading_ellipsis" = "..." ]; then
				loading_ellipsis=""
			else
				loading_ellipsis="$loading_ellipsis."
			fi
			wifi_status_color="#FF0000"	# color = red
		fi
	else
		download_speed="???"
		upload_speed="???"
		wifi_connected=""
		loading_ellipsis=""
		wifi_status="-🇼-"
		wifi_status_color="#999999"	# color = gray
	fi
}

echo '{"version":1}
['

first_line=true
while [ true ]; do
	stat_battery
	stat_volume
	stat_gpu
	stat_cpu
	stat_wifi
	time_and_date=`date +'%A, %B %e, %l:%M%p' | sed -r 's/  +/ /g'`
	
	leading_comma=","
	if [ "$first_line" ]; then
		leading_comma=""
		first_line=""
	fi
	
	echo "$leading_comma[`format_entry "$battery_status" $battery_status_color`,`format_entry "$volume_status" $volume_status_color`,`format_entry "$wifi_status" $wifi_status_color`,`format_entry "$gpu_status" $gpu_status_color`,`format_entry "$cpu_status" $cpu_status_color`,`format_entry "$time_and_date"`]"
	sleep 0.75
done
