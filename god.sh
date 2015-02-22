#!/bin/bash

foreground="\e[0;39m"
brown="\e[1;33m"
black="\e[0;30m"

server=irc.rizon.net
channel=grape
silent=false

in="$HOME/.punyama/text/$server/#$channel/in"
out="$HOME/.punyama/text/$server/#$channel/out"

if [[ "$#" -ge 1 ]]; then
	for flag in "$@"; do
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
				pkill -f "bash $HOME/.punyama/punyama.sh"
				;;
			-R)
				pkill "ii"
				pkill -f "bash $HOME/.punyama/punyama.sh"
				pkill -f "bash $HOME/.punyama/pegasus.sh"
				;;
			-s)
				silent=true
				;;
			-u)
				cd "$HOME/.punyama"
				git pull
				;;
		esac
	done
fi

if [[ -z "$(pgrep -f "ii -i "$HOME/.punyama/text" -s "$server" -n punyama")" ]]; then
	ii -i "$HOME/.punyama/text" -s "$server" -n punyama &
	if [[ "$silent" == false ]]; then
		echo "Starting ii."
	fi
	sleep 0.5

	echo "/j #$channel" > "$HOME/.punyama/text/$server/in"
	if [[ "$silent" == false ]]; then
		echo "Connecting to $channel@$server."
	fi
	sleep 0.5
elif [[ "$silent" == false ]]; then
	echo "ii is running."
fi

if [[ -z "$(pgrep -f "bash $HOME/.punyama/pegasus.sh")" ]]; then
	bash "$HOME/.punyama/pegasus.sh" & disown
	if [[ "$silent" == false ]]; then
		echo "Starting pegasus."
	fi
elif [[ "$silent" == false ]]; then
	echo "pegasus is running."
fi

if [[ -z "$(pgrep -f "bash $HOME/.punyama/punyama.sh")" ]]; then
	bash "$HOME/.punyama/punyama.sh" & disown
	if [[ "$silent" == false ]]; then
		echo "Starting punyama."
	fi
elif [[ "$silent" == false ]]; then
	echo "punyama is running."
fi

if [[ "$silent" == false ]]; then
	echo ""

	tailf -n 1 $out | \
	while read date time nick msg; do
		nick="${nick:1:-1}"

		if [[ "$nick" == "punyama" ]]; then
			echo -e "                 ^ <$black$nick$foreground> $msg"
		fi

		[[ "$nick" == "punyama" ]] && continue

		if [[ -n "$(echo "$msg" | grep -o "punyama")" ]]; then
			echo -e "$date $time - <$brown$nick$foreground> mentioned ${brown}punyama$foreground."
		fi

		if [[ "$msg" =~ https?:// ]]; then
			echo -e "$date $time - <$brown$nick$foreground> posted an ${brown}url$foreground."
		fi

		if [[ "$msg" == "tfw "* || "$msg" == ">tfw "* ]]; then
			echo -e "$date $time - <$brown$nick$foreground> posted a ${brown}feel$foreground."
		fi

		if [[ -n "$(echo "$msg" | grep "^.about\|^.bots\|^.calc\|^.count\|^.date\|^.day\|^.ded\|^.fortune\|^.graph\|^.grep\|^.intro\|^.kill\|^.ping\|^.pull\|^.reload\|^.source\|^.stopwatch\|^.time")" ]]; then
			echo -e "$date $time - <$brown$nick$foreground> used $brown$msg$foreground."
		fi
	done
fi
