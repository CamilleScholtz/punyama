#!/bin/bash

## CONFIGURATION

# Set bot dir location
botdir="$HOME/code/punyama"

# Set config dir location
configdir="$botdir/config"

# Set bot nick
botnick=punyama

# Set bot pass
botpass=Derpaderp1

# Set server
server="irc.rizon.net"

# Set colors
fg="\e[0;39m"
c1="\e[1;33m"
c2="\e[1;30m"
c3="\e[1;32m"

## FUCNTIONS

# This function starts ii and sets some variables
startii() {
	if [[ -z "$(pgrep "^ii$")" ]]; then
		echo "Starting ii."
		echo ""
		ii -i "$botdir/ii" -s "$server" -n $botnick & disown
	fi

	# Set server in & out paths
	si="$botdir/ii/$server/in"
	so="$botdir/ii/$server/out"

	# Msg NickServ
	echo "/j NickServ IDENTIFY $botpass" > "$si"
	sleep 0.5
}

# This function makes the bot join channels
join() {
	channels="$(cat "$configdir/channels")"

	for channel in $channels; do
		echo -e "Joining $c1$channel$fg."
		echo "/j $channel" > "$si"

		# Set channel in & out
		# TODO: Right now it echoes to all channels(?)
		i+="$botdir/ii/$server/$channel/in"
		o+="$botdir/ii/$server/$channel/out"
	done
	echo ""
}

# This function is used to skip disabled commands
truefalse() {
	# Load commands file
	. "$configdir/commands"

	# Ignore command if disabled
	if [[ "${!1}" == false ]]; then
		continue
	fi
}

# This function echoes to ii
echoii() {
	echo -e "$@" > "$i"

	echo -e "<$nick> $c1$msg$fg"
	echo -e " $c2->$fg $@"
}


## EXECUTE

startii
join

# Hello world
#echoii "Reporting in~"

tailf -n 1 "$o" | \
while read date time nick msg; do
	# Ignore self
	nick="${nick:1:-1}"
	if [[ "$nick" == "$botnick" ]]; then
		continue
	fi

	# Website title
	if [[ "$msg" =~ https?:// ]]; then
		truefalse "http"

		url="$(echo "$msg" | grep -o -P "http(s?):\/\/[^ \"\(\)\<\>]*")"
		title="$(curl -L -s "$url" | grep -i -P -o "(?<=<title>)(.*)(?=</title>)" | xml -q unesc)"

		if [[ -n "$(echo "$msg $title" | grep -i "porn\|penis\|sexy\|gay\|anal\|pussy\|/b/\|/h/\|/hm/\|/gif/\|nsfw\|gore\|sex\|lewd")" ]]; then
			echoii "[${c3}NSFW$fg] $title"
		else
			echoii "$title"
		fi
	fi

	# sed
	if [[ "$msg" =~ ^s/*/*/ ]]; then
		truefalse "sed"

		fix="$(tac "$o" | grep "<$nick>" | cut -d $'\n' -f 2 | cut -d " " -f 4- | sed "$msg")"
		echoii "<$nick> $fix"
	fi

	# Check if command
	if [[ "$msg" == "."* ]]; then
		case "$msg" in

			## ADMIN COMMANDS

			# Disable commands
			".disable "*)
				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -n "$(cat "$configdir/commands" | grep "^$query=true")" ]]; then
					sed -i "s/^$query=true/$query=false/" "$configdir/commands"
					echoii "Disabled $query~"
				elif [[ -n "$(cat "$configdir/commands" | grep "^$query=false")" ]]; then
					echoii "The commandtype $query is already disabled~"
				else
					echoii "The commandtype $query does not exist~"
				fi
			;;

			# Enable commands
			".enable "*)
				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -n "$(cat "$configdir/commands" | grep "^$query=false")" ]]; then
					sed -i "s/^$query=false/$query=true/" "$configdir/commands"
					echoii "Enabled $query~"
				elif [[ -n "$(cat "$configdir/commands" | grep "^$query=true")" ]]; then
					echoii "The commandtype $query is already enabled~"
				else
					echoii "The commandtype $query does not exist~"
				fi
			;;


			## ABOUT & HELP COMMANDS

			# Display some about info
			.about)
				hostname="$(hostname)"
				crux="$(crux)"
				if [[ -z "$crux" ]]; then
					distro="$(grep "PRETTY_NAME" "/etc/"*"-release" | cut -d '"' -f 2)"
				else
					distro="$crux"
				fi

				echoii "Hosted by $USER@$hostname, running $distro~"
				echoii "https://github.com/onodera-punpun/punyama"
			;;

			# Bots message
			.bots)
				echoii "Reporting in~ [bash]"
			;;

			# Send source link
			.source)
				echoii "https://github.com/onodera-punpun/punyama"
			;;



			## FUN COMMANDS

			# Ded message
			.ded)
				truefalse "fun"

				echoii "I'm still here~"
			;;

			# Get fortunes, currently supports 'quote'
			".fortune "*)
				truefalse "fun"

				query="$(echo "$msg" | cut -d " " -f 2)"

				case "$query" in
					quote)
						quote="$(grep -v "> \." "$o" | grep "<$nick>" | shuf -n 1 | cut -d " " -f 3-)"
						echoii "$quote"
					;;
				esac
			;;

			# Ping message
			.ping)
				truefalse "fun"

				echoii "pong~"
			;;

			# Allahu akbar
			.takbir)
				truefalse "fun"

				echoii "ALLAHU AKBAR~"
			;;


			## ACTUAL HELPFULL COMMANDS (lol)

			# Grep through history
			".grep "*)
				truefalse "grep"

				query="$(echo "$msg" | cut -d " " -f 2-)"

				results="$(grep -v "<punyama>" "$o" | grep -v "\-!\-" | grep -v "> \." | grep -i "$query" | cut -d " " -f 3-)"
				count="$(echo "$results" | wc -l)"

				# If more than 3 results, upload, else echo
				if [[ "$count" -ge 3 ]]; then
					echo "$results" > "/tmp/grep.txt"
					url="$(punf "/tmp/grep.txt" | cut -d " " -f 3)"

					echoii "$count results: $url"
				elif [[ -z "$results" ]]; then
					echoii "No results~"
				else
					echoii "$results"
				fi
			;;


			## ERRORS

			# Enable/disable error
			.enable|.disable)
				echoii "Please choose one of the following commandtypes: 'http' 'sed' 'fun' 'grep'~"
			;;

			# Fortune error
			.fortune)
				truefalse "fun"

				echoii "Please choose one of the following subjects: 'quote'~"
			;;

			# Grep error
			.grep)
				truefalse "grep"

				echoii "Please specify at least one search term~"
			;;

		esac
	fi
done
