#!/bin/bash

# Define default values
server=irc.freenode.net
channel=doingitwell
password=el_psy_congroo
silent=false

if [[ $# -ge 1 ]]; then
	for flag in "$@";do
		case "$flag" in
			-h|--help)
				echo "-h         help"
				echo "-r         reload"
				echo "-R         hard reload"
				echo "-s         silent"
				echo "-u         update"
				exit
				;;
		esac
	done

	for flag in "$@"; do
		case "$flag" in
			-r)
				pkill -f "bash $SCRIPTS/irc/punyama.sh"
				;;
			-R)
				pkill -f "bash $SCRIPTS/irc/punyama.sh"
				pkill -f "bash $SCRIPTS/irc/pegasus.sh"
				;;
			-s)
				silent=true
				;;
			-u)
				curl -s "$(cat $SCRIPTS/irc/link.txt)" > $SCRIPTS/irc/punyama.sh
				chmod +x $SCRIPTS/irc/punyama.sh
				;;
		esac
	done
fi

# Lauch ii
if [[ -z $(pgrep -f "ii -i $SCRIPTS/irc/text -s $server -n punyama") ]]; then
	ii -i $SCRIPTS/irc/text -s $server -n punyama &
	if [[ $silent == false ]]; then
		echo "Starting ii."
	fi
	sleep 0.5

	# Connect to channel
	echo "/j #$channel $password" > $SCRIPTS/irc/text/$server/in
	if [[ $silent == false ]]; then
		echo "Connecting to $channel@$server."
	fi
	sleep 0.5
elif [[ $silent == false ]]; then
	echo "ii is running."
fi

# Launch pegasus
if [[ -z $(pgrep -f "bash $SCRIPTS/irc/pegasus.sh") ]]; then
	bash $SCRIPTS/irc/pegasus.sh & disown
	if [[ $silent == false ]]; then
		echo "Starting pegasus."
	fi
elif [[ $silent == false ]]; then
	echo "pegasus is running."
fi

# Lauch punyama
if [[ -z $(pgrep -f "bash $SCRIPTS/irc/punyama.sh") ]]; then
	bash $SCRIPTS/irc/punyama.sh & disown
	if [[ $silent == false ]]; then
		echo "Starting punyama."
	fi
elif [[ $silent == false ]]; then
	echo "punyama is running."
fi

exit
