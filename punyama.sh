#!/bin/bash

# Define colors
foreground="\x03"
green="\x0303"
red="\x0305"

# Define default values
server=irc.freenode.net
channel=doingitwell
version=$(date +"%y%m%d-%H%M" -r $HOME/.punyama/punyama.sh)

# Make variables for in and out.
in=$HOME/.punyama/text/$server/\#$channel/in
out=$HOME/.punyama/text/$server/\#$channel/out

# Say hi
echo "Reporting in~" > $in

tailf -n 1 $out | \
while read date time nick msg; do

	# Strip < and >, if msg is by ourself ignore it
	nick="${nick:1:-1}"
	[[ $nick == "punyama" ]] && continue

	# Fix nicks
	shopt -s nocasematch
	if [[ $nick == "Vista-Narvas"* || $nick == "Vista_Narvas"* ]]; then
		nick=Vista-Narvas
	elif [[ $nick == "onodera"* || $nick == "kamiru"* || $nick == "camille"* ]]; then
		nick=onodera
	fi
	shopt -u nocasematch

	# Join stuff
	if [[ $nick == ! && -n $(tail -n 1 $out | grep "has joined") ]]; then
		fixednick=$(echo "$msg" | cut -d "(" -f 1)
		if [[ $fixednick == Vista_Narvas ]]; then
			fixednick=Vista-Narvas
		fi

		# Intro
		sleep 1
		cat $HOME/.punyama/intro.txt | grep $fixednick | cut -d " " -f 2- > $in
		# Message
		# TODO: Grep returns a non-critical error here
		if [[ -n $(cat $HOME/.punyama/msg.txt | grep $fixednick | cut -d " " -f 2-) ]]; then
			if [[ $fixednick == onodera ]]; then
				swapednick=Vista-Narvas
			elif [[ $fixednick == Vista-Narvas ]]; then
				swapednick=onodera
			fi

			sleep 0.5
			echo "$swapednick has left a message for you: $(cat $HOME/.punyama/msg.txt | grep $fixednick | cut -d " " -f 2-)" > $in
			sed -i "/$fixednick .*/d" $HOME/.punyama/msg.txt
		fi
	fi

	# Website stuff
	# TODO: filter png/jpg thingy
	if [[ $msg =~ https?:// && -z $(echo "$msg" | grep -i -s ".*[a-z0-9].png") && -z $(echo "$msg" | grep -i -s ".*[a-z0-9].jpg") ]]; then
		url=$(echo "$msg" | grep -o -P "http(s?):\/\/[^ \"\(\)\<\>]*")
		title=$(curl -s "$url" | grep -i -P -o "(?<=<title>)(.*)(?=</title>)" | xmlstarlet unesc)

		# Check if url is NSFW
		if [[ -n $(echo "$msg $title" | grep -i "porn\|penis\|sexy\|gay\|anal\|pussy\|/b/\|nsfw\|gore") ]]; then
			echo -e "(${red}NSFW$foreground) $title" > $in
		else
			echo "$title" > $in
		fi
	fi
	
	# Feel stuff
	if [[ $msg == "tfw "* || $msg == ">tfw "* ]]; then
		if [[ $msg == "tfw "* ]]; then
			msg=">$msg"
		fi

		echo "$green$msg" >> $HOME/.punyama/feel.txt
	fi

	# Check if command
	# TODO: Add .wkuk
	if [[ $msg == "."* ]]; then

		# Display detailed help
		if [[ $msg == ".help "* ]]; then
			word=$(echo $msg | sed 's/^\.help //')

			# TODO: Add detailed info
			# TODO: Add .help
			# TODO: Add .ded 
			case "$word" in
				about)
					echo "Display about message~" > $in
					;;
				calc)
					echo "Simple calculator~" > $in
					;;
				count)
					echo "Count how many times a word has been used or how many times a user has spoken, please specify at least one word or nick~" > $in
					;;
				date)
					echo "Shows the current date~" > $in
					;;
				day)
					echo "Shows the current day~" > $in
					;;
				fortune)
					echo "Gives a fortune, specify one of the following subjects: cookie paradox science tech" > $in
					;;
				git)
					echo "Give the github link~" > $in
					;;
				grep)
					echo "Grep through logs, please specify at least one word or nick~" > $in
					;;
				intro)
					echo "Set or display intro~" > $in
					;;
				last)
					echo "Shows the last three messages~" > $in
					;;
				msg)
					echo "Message a user, the message will be displayed the next time the user joins the channel or enters the .msg command~" > $in
					;;
				ping)
					echo "Pong~" > $in
					;;
				pull)
					echo "Pull in updates from git~" > $in
					;;
				random)
					echo "Get a random quote~" > $in
					;;
				reload)
					echo "Reloads me~" > $in
					;;
				stopwatch)
					echo "info about .stopwatch" > $in
					;;
				time)
					echo "info about .time" > $in
					;;
				*)
					echo "Not a valid command~" > $in
					;;
			esac

		# Display help
		elif [[ $msg == ".help" ]]; then
			echo -e ".about .calc($red!$foreground) .count .date .day .ded .feels .fortune .git .grep($red!$foreground) .intro .kill .last($red!$foreground) .msg .ping .pull($red!$foreground) .random($red!$foreground) .reload($red!$foreground) .stopwatch($red!$foreground) .time($red!$foreground)" > $in

		# About message
		elif [[ $msg == ".about" ]]; then
			uptime=$(ps -p $(pgrep -f "bash $HOME/.punyama/pegasus.sh" | tail -n 1) -o etime= | cut -d " " -f 4-)
			hostname=$(hostname)
			distro=$(cat /etc/*-release | grep "PRETTY_NAME" | cut -d '"' -f 2)

			echo "punyama version $version, alive for $uptime~" > $in
			echo "Hosted by $USER@$hostname, running $distro~" > $in
			echo "https://github.com/onodera-punpun/punyama"

		# Calculator
		# TODO: fix weird decimals
		elif [[ $msg == ".calc "* ]]; then
			word=$(echo $msg | cut -d " " -f 2-)

			echo "scale=3; $word" | bc > $in

		# Calculator error
		elif [[ $msg == ".calc" ]]; then
			echo "Please enter a calculation~" > $in

		# Count words
		elif [[ $msg == ".count "* ]]; then
			word=$(echo $msg | cut -d " " -f 2-)

			shopt -s nocasematch
			if [[ $word == "onodera" || $word == "kamiru" ]]; then
				results=$(cat $out | grep "<onodera>")
				echo "onodera has spoken $(echo "$results" | wc -l) times~" > $in
			elif [[ $word == "Vista-Narvas" || $word == "Vista_Narvas" ]]; then
				results=$(cat $out | grep "<Vista-Narvas>")
				echo "Vista-Narvas has spoken $(echo "$results" | wc -l) times~" > $in
			else
				results=$(cat $out | grep -v "<punyama>" | grep -v "\-!\-" | grep -v "> \." | grep -i "$word" | cut -d " " -f 3-)
				echo "This word has been used $(echo "$results" | wc -l) times~" > $in
			fi
			shopt -u nocasematch

		# Count error
		elif [[ $msg == ".count" ]]; then
			echo "Please specify at least one search term~" > $in

		# Check date
		elif [[ $msg == ".date" ]]; then
			date +"The date is %d %B~" > $in

		# Check day
		elif [[ $msg == ".day" ]]; then
			day=$(date +"%u")

			# TODO: Test this, make vista and onodera versions
			if [[ $day -le 5 ]]; then
				left=$(expr 6 - $(date +"%u"))

				if [[ $left -eq 1 ]]; then
					date +"Today is a %A, $left day left until weekend~" > $in
				else
					date +"Today is a %A, $left days left until weekend~" > $in
				fi
			else
				date +"Today is a %A~" > $in
			fi

		elif [[ $msg == ".ded" ]]; then
			echo "I'm still here~" > $in

		# Get dem feels
		# TODO: Add .feel *
		elif [[ $msg == ".feels" ]]; then
			feels=$(cat $HOME/.punyama/feel.txt)

			echo -e "$feels" > $in

		# Get a fortune
		elif [[ $msg == ".fortune"* ]]; then
			word=$(echo $msg | cut -d " " -f 2)

			if [[ $word == "tech" ]]; then
				fortune -a -s computers linux linuxcookie > $in
			elif [[ $word ==  "paradox" ]]; then
				fortune -a -s paradoxum > $in
			elif [[ $word == "science" ]]; then
				fortune -a -s science > $in
			elif [[ $word == "cookie" ]]; then
				fortune -a -s goedel > $in
			else
				echo "Please choose one of the following subjects: cookie paradox science tech" > $in
			fi

		elif [[ $msg == ".git" ]]; then
			echo "https://github.com/onodera-punpun/punyama" > $in

		# Grep through logs
		# TODO: Rice this with color.
		elif [[ $msg == ".grep "* ]]; then
			word=$(echo $msg | cut -d " " -f 2-)
			results=$(cat $out | grep -v "<punyama>" | grep -v "\-!\-" | grep -v "> \." | grep -i "$word" | cut -d " " -f 3-)
			#nick=$(echo "$results" | cut -d ">" -f 1 | grep -o -i "[a-z0-9\_\-]*")
			#msg=$(echo "$results" | cut -d ">" -f 2-)
			count=$(echo "$results" | wc -l)

			if [[ $count -ge 5 ]]; then
				echo "$results" | tail -n 3 > $in
				echo "$results" > $HOME/.punyama/grep.txt

				upload=$(curl --silent -sf -F files[]="@$HOME/.punyama/grep.txt" "http://pomf.se/upload.php")
				pomffile=$(echo "$upload" | grep -E -o '"url":"[A-Za-z0-9]+.txt",' | sed 's/"url":"//;s/",//')
				url=http://a.pomf.se/$pomffile

				echo "$(expr $count - 3 ) more results: $url" > $in
			elif [[ -z $results ]]; then
				echo "No results~" > $in
			else
				echo "$results" > $in
			fi

		# Grep error
		elif [[ $msg == ".grep" ]]; then
			echo "Please specify at least one search term~" > $in

		# Set intro message
		elif [[ $msg == ".intro "* ]]; then
			word=$(echo $msg | cut -d " " -f 2-)

			if [[ -z $(cat $HOME/.punyama/intro.txt | grep "$nick") ]]; then
				echo "$nick $word" >> $HOME/.punyama/intro.txt
				echo "Intro set~" > $in
			else
				sed -i "s/$nick .*/$nick $word/g" $HOME/.punyama/intro.txt
				echo "Intro set~" > $in
			fi

		# Get intro message
		elif [[ $msg == ".intro" ]]; then
			echo "Your intro is: $(cat $HOME/.punyama/intro.txt | grep $nick | cut -d " " -f 2-)" > $in

		# Display last written messages
		elif [[ $msg == ".last" ]]; then
			results=$(cat $out | grep -v "<punyama>" | grep -v "\-!\-" | grep -v "> \." | tail -n 3 | cut -d " " -f 3-)
			echo "$results" > $in

		# Leave message
		elif [[ $msg == ".msg "* ]]; then
			word=$(echo $msg | cut -d " " -f 2-)

			if [[ $nick == onodera ]]; then
			swapednick=Vista-Narvas
			elif [[ $nick == Vista-Narvas ]]; then
			swapednick=onodera
			fi

			if [[ -z $(cat $HOME/.punyama/msg.txt | grep "$swapednick") ]]; then
				echo "$swapednick $word" >> $HOME/.punyama/msg.txt
				echo "Message left~" > $in
			else
				sed -i "s/$swapednick .*/$swapednick $word/g" $HOME/.punyama/msg.txt
				echo "Message left~" > $in
			fi

		# Get message
		elif [[ $msg == ".msg" ]]; then
			# TODO: Grep returns a non-critical error here
			if [[ -n $(cat $HOME/.punyama/msg.txt | grep $nick | cut -d " " -f 2-) ]]; then
				if [[ $nick == onodera ]]; then
					swapednick=Vista-Narvas
				elif [[ $nick == Vista-Narvas ]]; then
					swapednick=onodera
				fi

				echo "$swapednick has left a message for you: $(cat $HOME/.punyama/msg.txt | grep $fixednick | cut -d " " -f 2-)" > $in
				sed -i "/$nick .*/d" $HOME/.punyama/msg.txt
			else
				echo "Sorry, you don't have any messages~" > $in
			fi

		# ping
		elif [[ $msg == ".ping" ]]; then
			echo "pong~" > $in

		# Post random quote
		# TODO: Rice this with color.
		# TODO: Ad random *.
		elif [[ $msg == ".random" ]]; then
			cat $out | grep -v "> \." | grep "<$nick>" | shuf -n 1 | cut -d " " -f 3- > $in

		# Stopwatch
		elif [[ $msg == ".stopwatch"* ]]; then
			word=$(echo $msg | cut -d " " -f 2)

			if [[ $word == "start" ]]; then
				if [[ $stopwatch -eq 0 ]]; then
					stopwatch=$(date +"%s")

					echo "The stopwatch is now running~" > $in
				else
					echo "The stopwatch is still running~" > $in
				fi

			elif [[ $word == "lap" ]]; then
				if [[ stopwatch -ne 0 ]]; then
					echo "$(echo "$(date +"%s")-$stopwatch" | bc) seconds have passed~" > $in
				else
					echo "The stopwatch is not running~" > $in
					echo "Use .stopwatch start to start the stopwatch~" > $in
				fi

			elif [[ $word ==  "stop" ]]; then
				if [[ stopwatch -ne 0 ]]; then
					echo "$(echo "$(date +"%s")-$stopwatch" | bc) seconds have passed~" > $in
					stopwatch=0
				else
					echo "Stopwatch is not running~" > $in
					echo "Use .stopwatch start to start the stopwatch~" > $in
				fi
			else
				echo "Please use one of the following options: start lap stop" > $in
			fi

		# TODO: Make output pretty
		elif [[ $msg == ".time till "* ]]; then
			word=$(echo $msg | cut -d " " -f 3-)
			# echo "$(echo "$(date -d $word +"%s")-$(date +"%s")"|bc) seconds till $word" > $in
	
			seconds=$(echo "$(date -d $word +"%s")-$(date +"%s")" | bc)
			minutes=$(echo "$seconds/60" | bc)
			hours=$(echo "$minutes/60" | bc)
			days=$(echo "$hours/24" | bc)

			seconds=$(echo "$seconds-$minutes*60" | bc)
			minutes=$(echo "$minutes-$hours*60" | bc)
			hours=$(echo "$hours-$days*60" | bc)

			if [[ $days -le 0 ]]; then
				days=""
				if [[ $hours -le 0 ]]; then
					hours=""
					if [[ $minutes -le 0 ]]; then
						minutes=""
						if [[ $seconds -le 0 ]]; then
							seconds=""
						fi
					fi
				fi
			fi

			echo "$days $hours $minutes $seconds" > $in


		# Check time
		# TODO: Add betime thingy
		elif [[ $msg == ".time" ]]; then
			day=$(date +"%u")
			time=$(date +"%H%M")
			current=$(date +"%I:%M %p~")
		
			if [[ $nick == onodera ]]; then
				end="17:30"
			elif [[ $nick == Vista-Narvas ]]; then
				end="17:00"
			fi
			
			seconds=$(echo "$(date -d $end +"%s")-$(date +"%s")" | bc)
		
			# TODO: Check if $day and -le work
			# TODO: Add -lt for 0900
			if [[ $day -le 5 && $end -gt 0 ]]; then
				minutes=$(echo "$seconds/60" | bc)
				hours=$(echo "$minutes/60" | bc)

				minutes=$(echo "$minutes-$hours*60" | bc)

				hoursword=" hours and "
				minutesword="minutes"

				if [[ $hours -eq 1 ]]; then
					hoursword=" hour and "
				fi
				if [[ $minutes -eq 1 ]]; then
					minutesword="minute"
				fi

				if [[ $hours -le 0 ]]; then
					hoursword=""
					hours=""
				fi
				if [[ $minutes -le 0 ]]; then
					hoursword=""
					minutes=""
				fi

				# TODO: Fix space when less than one hour
				echo "The time is $current, $hours$hoursword$minutes $minutesword left at work~" > $in
			else
				echo "The time is $current"
			fi
		fi
	fi

done > $in
