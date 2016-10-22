#!/bin/bash

volume=`amixer sget Master | grep 'Mono: Playback' | sed 's/.*Playback [0-9][0-9]* \[\([0-9][0-9]*\).*/\1/'`
if [ "$volume" -lt 100 ]; then
	pactl -- set-sink-volume 1 +5%
fi
