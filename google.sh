#!/bin/bash

GOOGLE_COLORS=('#00FF00' '#0000FF' '#FF0000' '#FFFF00')
Google_color_has_been_chosen=("" "" "" "")
chosen_colors=()
for index in {1..2}; do
	random_index=$(($RANDOM % 4))
	while [ ${Google_color_has_been_chosen[$random_index]} ]; do
		random_index=$(($RANDOM % 4))
	done
	chosen_colors[$index]=${GOOGLE_COLORS[$random_index]}
	Google_color_has_been_chosen[$random_index]=true
done

query=`echo "" | dmenu -p "Google: " -nf ${chosen_colors[1]} -nb ${chosen_colors[2]} -sf ${chosen_colors[1]} -sb ${chosen_colors[2]}` || exit

# URL encode the query
encoded_query=`python -c "import urllib; print urllib.quote(\"$query\")"`
# TODO TEMP
echo $encoded_query

google-chrome 'https://www.google.com/webhp?ion=1&espv=2&ie=UTF-8#q='"$encoded_query" --new-window
