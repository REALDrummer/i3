#!/bin/bash

message() {
	echo "$1"
	if [ "$notify" ]; then
		notify-send "$1"
	fi
}

# read arguments: [destination volume name] ("--notify")
destination_volume_name=""
notify=""
for argument in "$@"; do
	if [ "$argument" = "--notify" ]; then
		notify="true"
	elif [ "$destination_volume_name" ]; then
		message "You already specified a destination volume name; what does \"$argument\" mean?!"
		exit
	else
		destination_volume_name="$argument"
	fi
done
if [ "$destination_volume_name" = "" ]; then
	message "You forgot to tell the name of the volume that the home folder should be synced to!"
	exit
fi
DESTINATION=/media/variadicism/"$1"/

if [ ! -d "$DESTINATION" ]; then
	message "$destination_volume_name is not mounted!"
	exit 
fi

gnome-terminal -x sudo rsync --verbose --progress --compress --rsh=/usr/local/bin/ssh --recursive --times --perms --links --delete --partial --exclude=/home/variadicism/Downloads/* --exclude=/home/variadicism/Trash/* /home/variadicism/. "$DESTINATION"
echo "Unlocking permissions on destination drive..."
chmod -R 777 "$DESTINATION"
echo "Done!"
