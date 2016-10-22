# see if they wanted to block with i3lock, i.e. not run the next command until the screen was unlocked
block=""
dim="true"
for arg in "$@"; do
	if [ "$arg" == "--block" ]; then
		block="true"
	elif [ "$dim" == "--no-dim" ]; then
		dim=""
	else
		echo "Warning: I don't know what \"$arg\" means!" >&2
	fi
done

lock_and_brighten() {
	i3lock -n -i "/home/variadicism/Pictures/background Print Gallery.png"
	if [ "$dim" ]; then
		xbacklight -set $old_backlight_setting
	fi
}

if [ "$dim" ]; then
	old_backlight_setting=`xbacklight`
	xbacklight -set 0
fi
if [ "$block" ]; then
	lock_and_brighten
else
	lock_and_brighten &
fi
