source ~/BASH\ utils/i3ws.sh

current_workspace=`i3ws`
i3-msg workspace "5 music" > /dev/null
xdotool key space
i3-msg workspace "$current_workspace" > /dev/null
