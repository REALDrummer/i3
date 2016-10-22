try_disconnect() {
	# 1 required argument: the name of the output to attempt to disconnect
	# outputs an error message if the output could not be disconnected; nothing otherwise
	
	output_used=`xrandr | grep -E -n "$1"'\s*connected\s+[^(]'`
	if [ "$output_used" ]; then
		xrandr --output "$1" --off
	else
		echo "$1 is not connected!"
	fi
}

try_connect() {
	# 1 required argument: the name of the output to attempt to connect
	# outputs an error message if the output could not be connected; nothing otherwise
	
	output_connected=`xrandr | grep -E -n "$1"'\s*connected'`
	output_used=`xrandr | grep -E -n "$1"'\s*connected\s+[^(]'`
	if [ "$output_connected" ] && [ ! "$output_used" ]; then
		# TODO: make this take all the available modes and sort them and pick the highest resolution
		xrandr --output "$1" --right-of LVDS1 --auto
	else
		echo "I could not connect to $1!"
	fi
}

# if HDMI1 is connected, disconnect it
if [ ! "`try_disconnect "HDMI1"`" ]; then
	exit
fi

# if VGA1 is connected, disconnect it
if [ ! "`try_disconnect "VGA1"`" ]; then
	exit
fi

# if HDMI1 is available for connection, try to connect to it
if [ ! "`try_connect "HDMI1"`" ]; then
	exit
fi

# if VGA1 is available for connection, try to connect to it
if [ ! "`try_connect "VGA1"`" ]; then
	exit
fi

# if we get here, there was nothing to be done
echo "I couldn't find any monitors to connect to and you're already disconnected from everything!"
