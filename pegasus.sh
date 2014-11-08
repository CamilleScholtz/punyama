#!/bin/bash

# Define default values
server=irc.freenode.net
channel=doingitwell

# Make variables for in and out.
in=$SCRIPTS/irc/text/$server/\#$channel/in
out=$SCRIPTS/irc/text/$server/\#$channel/out

tailf -n 1 $out | \
while read date time nick msg; do

	# Strip < and >, if msg is by ourself ignore it
	nick="${nick:1:-1}"
	[[ $nick == "punyama" ]] && continue

	# Check if command
	if [[ $msg == "."* ]]; then

		# Pull in updates
		# TODO: Add some kind of confirmation
		if [[ $msg == ".pull" ]]; then
			bash $SCRIPTS/irc/god.sh -u -s
			echo "Pulled in updates, pls .reload me~" > $in

		# Push in updates
		# TODO: Add some kind of confirmation
		elif [[ $msg == ".push "* ]]; then
			word=$(echo $msg | cut -d " " -f 2)

			echo "$word" > $SCRIPTS/irc/link.txt
			echo "Pushed in updates, pls .pull~" > $in

		# Push error
		elif [[ $msg == ".push" ]]; then
			echo "Please provide a link~" > $in

		# Reload punyama
		elif [[ $msg == ".reload" ]]; then
			bash $SCRIPTS/irc/god.sh -r -s
		fi
	fi

done > $in
