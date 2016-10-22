#!/bin/bash

choice=`iwlist wlp2s0 scan >&1 | grep --color=never -E 'ESSID:"[^"]' | sed -r 's/^.+ESSID:"([^"]+)".*/\1/g' | dmenu -p 'Wi-Fi' -nb "#EEEEEE"`
sudo iwconfig wlp2s0 essid "$choice"
# TODO: how to actually "connect" from here?
# TODO: if Wi-Fi passwords are saved somewhere, so they need to be added as part of the command here?
