getSkypePID() {
	echo `ps aux | grep -E '[0-9]:[0-9][0-9]\s*skype' | sed -r 's/\w+\s*([0-9]+).+/\1/g'`
}

# if Skype is still running, try to shut it down or kill it
Skype_PID=`getSkypePID`
if [ "$Skype_PID" ]; then
	# first, try to kill it with default settings
	kill $Skype_PID
	sleep 5
	
	# if Skype is still running, kill it with SIGKILL (9)
	kill -9 $Skype_PID
fi

# start or restart Skype
skype
