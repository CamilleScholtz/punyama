#!/bin/bash

# Define default values
server=irc.freenode.net
channel=doingitwell

# Make variables for in and out.
in=$HOME/.punyama/text/$server/\#$channel/in
out=$HOME/.punyama/text/$server/\#$channel/out

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
			bash $HOME/.punyama/god.sh -u -s
			echo "Pulled in updates, pls .reload me~" > $in

		# Reload punyama
		elif [[ $msg == ".reload" ]]; then
			bash $HOME/.punyama/god.sh -r -s
		fi
	fi

done > $in
