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

# Set colors (term)
fg="\e[0;39m"
c1="\e[1;31m"
c2="\e[1;33m"
c3="\e[1;30m"


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
		echo "Joining $channel."
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
	if [[ -n "$@" ]]; then
		echo -e "​$@" > "$i"
	fi

	echo -e "<$nick> $c2$msg$fg"
	# TODO: Make this support multi line stuff
	echo -e " $c3->$fg $@"
}


## EXECUTE

startii
join

# Set colors (irc)
fgii="\x03"
c1ii="\x034"

# Hello world
#echoii "Reporting in~"

tailf -n 1 "$o" | \
while read date time nick msg; do
	# Website title
	if [[ "$msg" =~ https?:// ]]; then
		truefalse "http"

		url="$(echo "$msg" | grep -o -P "http(s?):\/\/[^ \"\(\)\<\>]*")"
		title="$(curl -L -s "$url" | grep -i -P -o "(?<=<title>)(.*)(?=</title>)" | xml -q unesc)"

		if [[ -n "$(echo "$msg $title" | grep -i "porn\|penis\|hentai\|gay\|anal\|pussy\|vagina\|/b/\|/hm/\|/gif/\|nsfw\|gore\|sex\|lewd")" ]]; then
			echoii "[${c1ii}NSFW$fgii] $title"
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

			# TODO: Add list command
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

			# Random fortune message
			".fortune "*)
				truefalse "fun"

				query="$(echo "$msg" | cut -d " " -f 2)"

				case "$query" in
					keynpeele|mega64|nasheed|nichijou|onion|wkuk)
						echoii "$(cat "$configdir/fortune/$query" | shuf -n 1)"
						;;
					quote)
						# TODO: Make other nicks quotable
						echoii "$(grep -v "> \." "$o" | grep -v "<$botnick>" | grep "<$nick>" | shuf -n 1 | cut -d " " -f 3-)"
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

				results="$(grep -v "<$botnick>" "$o" | grep -v "\-!\-" | grep -v "> \." | grep -i "$query" | cut -d " " -f 3-)"
				count="$(echo "$results" | wc -l)"

				# If more than 3 results, upload, else echo
				if [[ "$count" -ge 3 ]]; then
					echo "$results" > "/tmp/grep.txt"
					url="$(punf -q "/tmp/grep.txt")"

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

				echoii "Please choose one of the following subjects: 'keynpeele' 'mega64' 'nasheed' 'nichijou' 'onion' 'wkuk' 'quote'~"
			;;

			# Grep error
			.grep)
				truefalse "grep"

				echoii "Please specify at least one search term~"
			;;
		esac
	fi
done
