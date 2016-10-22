#!/bin/bash

# parse command line arguments
start_folder="/home/`whoami`"
show_hidden=""
with_sudo=""
color=""
for arg in "$@"; do
	if [ "$arg" = "--show-hidden-files" ]; then
		show_hidden="true"
	elif [ "$arg" = "--sudo" ]; then
		with_sudo="sudo"
		color="-nb #770000"
		start_folder=/
	elif [ -d "$arg" ]; then
		start_folder="$arg"
	else
		notify-send "The dmenu with files script got an unrecognized argument: \"$arg\"!" --urgent normal --expire-time 60
	fi
done

try_mkdir() {
	mkdir_result=`$with_sudo mkdir -p "$1" 2>&1`
	if [ "$mkdir_result" ]; then
		notify-send "$mkdir_result"
		return -1
	fi
}

dmenu_from_folder() {
	choice=""
	if [ ! -d "$1" ]; then
		choice=`echo "" | dmenu $color`
	elif [ $show_hidden ]; then
		choice=`ls -a "$1" --color=never | tail -n +2 | dmenu $color`
	else
		ls_result=`ls "$1" --color=never`
		choice=`echo $'..\n'"$ls_result" | dmenu $color`
	fi
	file="$1/$choice"
	if [ "$choice" != "" ]; then
		if [ "$choice" = "./t" ]; then
			# open this folder in the terminal
			try_mkdir "$1" && gnome-terminal --working-directory="$1"
		elif [ "$choice" = "./" ]; then
			# open up this folder in nemo (without starting the desktop)
			try_mkdir "$1" && nemo "$1"
		elif [ "$choice" = "/" ]; then
			# go up to the root directory
			dmenu_from_folder /
		elif [ -f "$file" ]; then
			try_mkdir "$1" && xdg-open "$file"
		elif [ -d "$file" ]; then
			dmenu_from_folder "$file"
		elif [[ "$choice" =~ .*/ ]]; then
			dmenu_from_folder "$1/$choice"
		else
			# make a new file
			try_mkdir "$1" && gedit "$1/$choice"
		fi
	fi
}

dmenu_from_folder "$start_folder"
