#!/bin/bash

## CONFIGURATION

# Set bot dir location
botdir="$HOME/code/punyama"

# Set config dir location
configdir="$botdir/config"

# Set bot nick
botnick=punyama

# Set bot pass
botpass=derpaderp1

# Set server
server="irc.rizon.net"

# Set colors (term)
fg="\e[0;39m"
c1="\e[1;33m"
c2="\e[1;30m"


## FUCNTIONS

# This function starts ii and sets some variables
startii() {
	if [[ -z "$(pgrep "^ii$")" ]]; then
		echo "Starting ii."
		echo ""
		ii -i "$botdir/ii" -s "$server" -n $botnick & disown
	fi

	# Set server in path
	serverin="$botdir/ii/$server/in"
}

# This function makes the bot join channels
join() {
	# Msg NickServ
	echo "IDENTIFY $botpass" > "$botdir/ii/$server/nickserv/in"
	sleep 1

	channels="$(cat "$configdir/channels")"

	for channel in $channels; do
		echo -e "Joining $c1$channel$fg."
		echo "/j $channel" > "$serverin"

		# Set channel out path
		out+="$botdir/ii/$server/$channel/out "
	done
	echo ""
}

# This function is used to skip admin command
admin() {
	if [[ -z "$(grep "^$nick$" "$configdir/admin")" ]]; then
		echoii "Check your privilege~"

		continue
	fi
}

# This function is used to skip disabled commands
truefalse() {
	# Load truefalse file
	. "$configdir/truefalse/$activechannel"

	# Ignore command if disabled
	if [[ "${!1}" == false ]]; then
		continue
	fi
}

# This function echoes to ii
echoii() {
	echo -e "​$@" > "$botdir/ii/$server/$activechannel/in"

	echo -e "<$c1$nick$c2@$c1$activechannel$fg> $msg"
	# TODO: Make this support multi line stuff
	echo -e "$c2->$fg $@"
}


## EXECUTE

startii
join

# Set colors (irc)
fgii="\x03"
c1ii="\x034"
c2ii="\x033"

# Hello world
#echoii "Reporting in~"

tail -f -v -n 1 $out | \
while read date time nick msg; do
	# Check channel
	if [[ "$date" == "==>" ]]; then
		activechannel="$(echo "$time" | rev | cut -d "/" -f 2 | rev)"

		continue
	fi

	# Fix nicks
	nick="${nick:1:-1}"

	# Ignore nicks
	if [[ -n "$(grep "^$nick$" "$configdir/ignore")" ]]; then
		continue
	fi

	# Website title
	if [[ "$msg" =~ https?:// ]]; then
		truefalse "http"

		url="$(echo "$msg" | grep -o -P "http(s?):\/\/[^ \"\(\)\<\>]*")"
		# TODO: unesc doesn't always work
		title="$(curl -L -s "$url" | grep -i -P -o "(?<=<title>)(.*)(?=</title>)" | xml -q unesc)"

		if [[ -n "$title" ]]; then
			if [[ -n "$(echo "$msg $title" | grep -i "/b/\|/hm/\|/gif/\|anal\|dildo\|gore\|hentai\|lewd\|nude\|nsfw\|penis\|porn\|pussy\|sex\|vagina\|yuri")" ]]; then
				echoii "[${c1ii}NSFW$fgii] $title"
			else
				echoii "$title"
			fi
		fi

		if [[ "$url" =~ pomf.se ]]; then
			echoii "rip~"
		fi

		continue
	fi

	# sed
	if [[ "$msg" =~ ^s/*/*/ ]]; then
		truefalse "sed"

		fix="$(tac "$botdir/ii/$server/$activechannel/out" | grep -v "<$botnick>" | grep "<$nick>" | cut -d $'\n' -f 2 | cut -d " " -f 4- | sed "$msg")"
		if [[ "$?" -eq 0 ]]; then
			echoii "<$nick> $fix"
		fi

		continue
	fi

	# Feels
	if [[ "$msg" == "tfw "* || "$msg" == ">tfw "* || "$msg" == "3>tfw "* ]]; then
		# TODO: Fix non green feel
		if [[ "$msg" == "tfw "* ]]; then
			msg=">$msg"
		fi

		echo "$c3ii$msg" >> "$configdir/random/feel"

		echoii "iktf"

		continue
	fi

	# Check if command
	if [[ "$msg" == "."* ]]; then
		case "$msg" in

			# TODO: Make false/true chanel specific (put the file in channeldir?)
			## ADMIN COMMANDS

			# Disable commands
			".false "*)
				admin

				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -n "$(cat "$configdir/truefalse/$activechannel" | grep "^$query=true")" ]]; then
					sed -i "s/^$query=true/$query=false/" "$configdir/truefalse/$activechannel"
					echoii "Command '$query' is now set to false~"
				elif [[ -n "$(cat "$configdir/truefalse/$activechannel" | grep "^$query=false")" ]]; then
					echoii "Command '$query' is already set to false~"
				else
					echoii "Command '$query' does not exist~"
				fi
			;;

			# Enable commands
			".true "*)
				admin

				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -n "$(cat "$configdir/truefalse/$activechannel" | grep "^$query=false")" ]]; then
					sed -i "s/^$query=false/$query=true/" "$configdir/truefalse/$activechannel"
					echoii "Command '$query' is now set to true~"
				elif [[ -n "$(cat "$configdir/truefalse/$activechannel" | grep "^$query=true")" ]]; then
					echoii "Command '$query' is already set to true~"
				else
					echoii "Command '$query' does not exist~"
				fi
			;;

			# Ignore nicks
			".ignore "*)
				admin

				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -z "$(cat "$configdir/ignore" | grep "^$query$")" ]]; then
					echo "$query" >> "$configdir/ignore"
					echoii "Ignoring $query~"
				else
					echoii "$query is already being ignored~"
				fi
			;;

			# Unignore nicks
			".unignore "*)
				admin

				query="$(echo "$msg" | cut -d " " -f 2)"

				if [[ -n "$(cat "$configdir/ignore" | grep "^$query$")" ]]; then
					sed -i "/^$query$/d" "$configdir/ignore"
					echoii "Unignoring $query~"
				else
					echoii "$query is not being ignored already~"
				fi
			;;


			# List commands
			.list)
				echoii "$(cat "$configdir/truefalse/$activechannel" | tr "\n" " ")"
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
				truefalse "ded"

				echoii "I'm still here~"
			;;

			# Ping message
			.ping)
				truefalse "ping"

				echoii "pong~"
			;;

			# Get r8ed m8
			.r8)
				truefalse "r8"

				echoii "$(r8)"
			;;

			# Random message
			".random "*)
				truefalse "random"

				query="$(echo "$msg" | cut -d " " -f 2)"

				case "$query" in
					feel|keynpeele|mega64|nasheed|nichijou|onion|wkuk)
						echoii "$(cat "$configdir/random/$query" | shuf -n 1)"
						;;
					quote)
						query="$(echo "$msg" | cut -d " " -f 3)"
						if [[ -z "$query" ]]; then
							query="$nick"
						fi

						result="$(grep -v "> \." "$botdir/ii/$server/$activechannel/out" | grep -v "<$botnick>" | grep "<$query>" | shuf -n 1 | cut -d " " -f 3-)"

						if [[ -n "$result" ]]; then
							echoii "$result"
						else
							echoii "$query hasn't said anything in this channel~"
						fi
						;;
					*)
						echoii "Please choose one of the following subjects: 'feel' 'keynpeele' 'mega64' 'nasheed' 'nichijou' 'onion' 'wkuk' 'quote'~"
						;;
				esac
			;;

			# Allahu akbar
			.takbir)
				truefalse "takbir"

				echoii "ALLAHU AKBAR~"
			;;


			## ACTUAL HELPFULL COMMANDS (lol)

			# Grep through history
			".grep "*)
				truefalse "grep"

				query="$(echo "$msg" | cut -d " " -f 2-)"

				result="$(grep -v "<$botnick>" "$botdir/ii/$server/$activechannel/out" | grep -v "\-!\-" | grep -v "> \." | grep -i "$query" | cut -d " " -f 3-)"
				count="$(echo "$result" | wc -l)"

				# If more than 3 results, upload, else echo
				if [[ "$count" -ge 3 ]]; then
					echo "$result" > "/tmp/grep.txt"
					url="$(punf -q "/tmp/grep.txt")"

					echoii "$count results: $url"
				elif [[ -z "$result" ]]; then
					echoii "No results~"
				else
					echoii "$result"
				fi
			;;


			## ERRORS

			# Enable/disable error
			.true|.false)
				admin

				echoii "Please specify one of the commands found in .list~"
			;;

			# Enable/disable error
			.ignore\|.unignore)
				admin

				echoii "Please specify a nick~"
			;;

			# Random error
			.random)
				truefalse "random"

				echoii "Please choose one of the following subjects: 'feel' 'keynpeele' 'mega64' 'nasheed' 'nichijou' 'onion' 'wkuk' 'quote'~"
			;;

			# Grep error
			.grep)
				truefalse "grep"

				echoii "Please specify a search term~"
			;;
		esac
	fi
done
