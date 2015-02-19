#!/bin/bash

# TODO: Move git to source

foreground="\x03"
green="\x0303"
red="\x0305"

server=irc.rizon.net
channel=grape
version="$(date +"%y%m%d-%H%M" -r "$HOME/.punyama/punyama.sh")"

in="$HOME/.punyama/text/$server/#$channel/in"
out="$HOME/.punyama/text/$server/#$channel/out"

echo "Reporting in~" > "$in"

tailf -n 1 $out | \
while read date time nick msg; do

	nick="${nick:1:-1}"
	[[ "$nick" == "punyama" ]] && continue

	if [[ "$nick" == "!" && -n "$(tail -n 1 "$out" | grep "has joined")" ]]; then
		fixednick="$(echo "$msg" | cut -d "(" -f 1)"

		sleep 0.5
		grep "$fixednick" "$HOME/.punyama/config/intro.txt" | cut -d " " -f 2- > "$in"
	fi

	# TODO: filter png/jpg thingy
	if [[ "$msg" =~ https?:// && -z "$(echo "$msg" | grep -i -s ".*[a-z0-9].png")" && -z "$(echo "$msg" | grep -i -s ".*[a-z0-9].jpg")" ]]; then
		url="$(echo "$msg" | grep -o -P "http(s?):\/\/[^ \"\(\)\<\>]*")"
		title="$(curl -s "$url" | grep -i -P -o "(?<=<title>)(.*)(?=</title>)" | xmlstarlet unesc)"

		if [[ -n "$(echo "$msg $title" | grep -i "porn\|penis\|sexy\|gay\|anal\|pussy\|/b/\|/h/\|/hm/\|/gif/\|nsfw\|gore")" ]]; then
			echo -e "(${red}NSFW$foreground) $title" > "$in"
		else
			echo "$title" > "$in"
		fi
	fi
	
	if [[ $msg == "tfw "* || $msg == ">tfw "* ]]; then
		if [[ $msg == "tfw "* ]]; then
			msg=">$msg"
		fi

		echo "$green$msg" >> "$HOME/.punyama/config/feel.txt"
	fi

	if [[ "$msg" == "."* ]]; then
		case "$msg" in
			".help "*)
				word="$(echo "$msg" | sed 's/^\.help //')"

				case "$word" in
					about)
						echo "Display about message~" > "$in"
						;;
					calc)
						echo "Simple calculator~" > "$in"
						;;
					count)
						echo "Count how many times a word has been used or how many times a user has spoken, please specify at least one word or nick~" > "$in"
						;;
					date)
						echo "Shows the current date~" > "$in"
						;;
					day)
						echo "Shows the current day~" > "$in"
						;;
					fortune)
						echo "Gives a fortune, specify one of the following subjects: feel nichijou wkuk quote" > "$in"
						;;
					source)
						echo "Links the punyama source~" > "$in"
						;;
					grep)
						echo "Grep through logs, please specify at least one word or nick~" > "$in"
						;;
					intro)
						echo "Set or display intro~" > "$in"
						;;
					ping)
						echo "Pong~" > "$in"
						;;
					pull)
						echo "Pull in updates from git~" > "$in"
						;;
					reload)
						echo "Reloads me~" > "$in"
						;;
					stopwatch)
						echo "Tracks time, use start or stop to start or stop the stopwatch~" > "$in"
						;;
					time)
						echo "Usage: .stopwatch [OPTION]... [TIME]..." > "$in"
						echo "Display the current time" > "$in"
						echo "  until     calculate difrence between now and the given time" > "$in"	
						;;
					*)
						echo "Not a valid command~" > "$in"
						;;
				esac
				;;
			.help)
				echo -e ".about .bots .calc .count .date .day .ded .fortune .graph .grep .intro .kill .ping .pull .reload .source .stopwatch .time" > "$in"
				;;
			.about)
				# TODO: Fix uptime
				#uptime="$(ps -p $(pgrep -f "bash $HOME/.punyama/pegasus.sh" | tail -n 1) -o etime= | cut -d " " -f 4-)"
				hostname="$(hostname)"
				crux="$(crux)"
				if [[ -z "$crux" ]]; then
					distro="$(grep "PRETTY_NAME" "/etc/"*"-release" | cut -d '"' -f 2)"
				else
					distro="$crux"
				fi

				echo "punyama version $version, alive for $uptime~" > "$in"
				echo "Hosted by $USER@$hostname, running $distro~" > "$in"
				echo "https://github.com/onodera-punpun/punyama"
				;;
			.bots)
				echo "Reporting in~ [bash]" > "$in"
				;;
			".calc "*)
				word="$(echo "$msg" | cut -d " " -f 2-)"

				echo "$((word))" > "$in"
				;;
			.calc)
				echo "Please enter a calculation~" > "$in"
				;;
			# TODO: Fix weird user name shit
			#.count *)
			#	word="$(echo "$msg" | cut -d " " -f 2-)"

			#	shopt -s nocasematch
			#	if [[ $word == "onodera" || $word == "kamiru" ]]; then
			#		results=$(grep -c "<onodera>" "$out")
			#		echo "onodera has spoken $results times~" > "$in"
			#	elif [[ $word == "Vista-Narvas" || $word == "Vista_Narvas" ]]; then
			#		results=$(grep -c "<Vista-Narvas>" "$out")
			#		echo "Vista-Narvas has spoken $results times~" > "$in"
			#	else
			#		results=$(grep -v "<punyama>" "$out" | grep -v "\-!\-" | grep -v "> \." | grep -i "$word" | cut -d " " -f 3- | wc -l)
			#		echo "$word has been used $results times~" > "$in"
			#	fi
			#	shopt -u nocasematch
			#	;;
			.count)
				echo "Please specify at least one search term~" > "$in"
				;;
			.date)
				date +"The date is %d %B~" > "$in"
				;;
			.day)
				day="$(date +"%u")"

				if [[ "$day" -le 5 ]]; then
					left="$((6-$(date +"%u")))"

					if [[ "$left" -eq 1 ]]; then
						date +"Today is a %A, $left day left until weekend~" > "$in"
					else
						date +"Today is a %A, $left days left until weekend~" > "$in"
					fi
				else
					date +"Today is a %A~" > "$in"
				fi
				;;
			.ded)
				echo "I'm still here~" > "$in"
				;;
			".fortune "*)
				word="$(echo "$msg" | cut -d " " -f 2)"

				case "$word" in
					feel)
						echo -e "$(shuf -n 1 "$HOME/.punyama/config/feel.txt")" > "$in"
						;;
					nichijou)
						echo "Here is your 日常 fix: $(shuf -n 1 "$HOME/.punyama/config/nichijou.txt")" > "$in"
						;;
					wkuk)
						echo "Here is your WKUK fix: $(shuf -n 1 "$HOME/.punyama/config/wkuk.txt")" > "$in"
						;;
					quote)
						# TODO: Rice this with color.
						grep -v "> \." "$out" | grep "<$nick>" | shuf -n 1 | cut -d " " -f 3- > "$in"
						;;
				esac
				;;
			.fortune)
				echo "Please choose one of the following subjects: feel nichijou wkuk quote" > "$in"
				;;
			".graph "*)
				word="$(echo "$msg" | cut -d " " -f 2-)"

				shopt -s nocasematch
				if [[ "$word" -eq 2 ]]; then
					# TODO: Fix this one (something with time)
					word1="$(echo "$word" | cut -d " " -f 1)"
					word2="$(echo "$word" | cut -d " " -f 2)"

					results1="$(grep -E -v "<punyama>|\-\!\-" "$out" | grep "$word1" | cut -d " " -f -3)"
					results2="$(grep -E -v "<punyama>|\-\!\-" "$out" | grep "$word2" | cut -d " " -f -3)"

					echo "$results1" | cut -d " " -f 1 | uniq -c | sed "s/^\s*//" > "/tmp/count1.txt"
					echo "$results2" | cut -d " " -f 1 | uniq -c | sed "s/^\s*//" | cut -d " " -f 1 > "/tmp/count2.txt"
					paste -d " " "/tmp/count2.txt" "/tmp/count1.txt" > "/tmp/count.txt"

					gnuplot -e "set terminal png tiny size '768x480';set title 'Stats for $word1 and $word2~';set format x '%Y-%m-%d';set xdata time;set timefmt '%Y-%m-%d';set xrange [ '2014-09-14' : '$(date +"%Y-%m-%d")' ];set style fill pattern 1 border;set boxwidth 24*3600 absolute;plot '/tmp/count.txt' using 3:(\$2+\$1) with boxes title '$word1' lt -1,'' using 3:1 with boxes title '$word2' lt -1;" > "/tmp/graph.png"

					url="$(pomf "/tmp/graph.png")"

					echo "Here is your graph for $word1 and $word2: $url"
				elif [[ "$word" -eq 1 ]]; then
					results="$(grep -E -v "<punyama>|\-\!\-" "$out" | grep "$word" | cut -d " " -f -3)"

					countndate="$(echo "$results" | cut -d " " -f 1 | uniq -c | sed "s/^\s*//")"
					echo "$countndate" > "/tmp/count.txt"

					gnuplot -e "set terminal png tiny size '768x480';set title 'Stats for $word~';set format x '%Y-%m-%d';set xdata time;set timefmt '%Y-%m-%d';set xrange [ '2014-09-14' : '$(date +"%Y-%m-%d")' ];set style fill pattern 1 border;set boxwidth 24*3600 absolute;plot '/tmp/count.txt' using 2:1 with boxes notitle lt -1;" > "/tmp/graph.png"

					url="$(pomf "/tmp/graph.png")"

					echo "Here is your graph for $word: $url"
				else
					echo "Please specify 2 words or less~" > "$in"
				fi
				shopt -u nocasematch
				;;
			.graph)
				echo "Please specify at least one search term~" > "$in"
				;;
			# TODO: Rice this with color
			".grep "*)
				word="$(echo "$msg" | cut -d " " -f 2-)"

				results="$(grep -v "<punyama>" "$out" | grep -v "\-!\-" | grep -v "> \." | grep -i "$word" | cut -d " " -f 3-)"
				#nick=$(echo "$results" | cut -d ">" -f 1 | grep -o -i "[a-z0-9\_\-]*")
				#msg=$(echo "$results" | cut -d ">" -f 2-)
				count="$(echo "$results" | wc -l)"

				if [[ "$count" -ge 5 ]]; then
					echo "$results" | tail -n 3 > "$in"
					echo "$results" > "/tmp/grep.txt"

					url="$(pomf "/tmp/grep.txt")"

					echo "$((count-3)) more results: $url" > "$in"
				elif [[ -z "$results" ]]; then
					echo "No results~" > "$in"
				else
					echo "$results" > "$in"
				fi
				;;
			.grep)
				echo "Please specify at least one search term~" > "$in"
				;;
			".intro "*)
				word="$(echo "$msg" | cut -d " " -f 2-)"

				if [[ -z "$(grep "$nick" "$HOME/.punyama/config/intro.txt")" ]]; then
					echo "$nick $word" >> "$HOME/.punyama/config/intro.txt"
					echo "Intro set~" > "$in"
				else
					sed -i "s/$nick .*/$nick $word/g" "$HOME/.punyama/config/intro.txt"
					echo "Intro set~" > "$in"
				fi
				;;
			.intro)
				echo "Your intro is: $(grep $nick "$HOME/.punyama/config/intro.txt" | cut -d " " -f 2-)" > "$in"
				;;
			.ping)
				echo "pong~" > "$in"
				;;
			.source)
				echo "https://github.com/onodera-punpun/punyama" > "$in"
				;;
			".stopwatch "*)
				word="$(echo "$msg" | cut -d " " -f 2)"

				if [[ "$word" == start ]]; then
					if [[ "$stopwatch" -eq 0 ]]; then
						stopwatch="$(date +"%s")"

						echo "The stopwatch is now running~" > "$in"
					else
						echo "The stopwatch is still running~" > "$in"
					fi
				elif [[ "$word" ==  "stop" ]]; then
					if [[ "$stopwatch" -ne 0 ]]; then
						echo "Stopping stopwatch, $(((date +"%s") - stopwatch)) seconds have passed~" > "$in"
						stopwatch=0
					else
						echo "Stopwatch is not running~" > "$in"
						echo "Use .stopwatch start to start the stopwatch~" > "$in"
					fi
				else
					if [[ "$stopwatch" -ne 0 ]]; then
						echo "$(((date +"%s") - stopwatch)) seconds have passed~" > "$in"
					else
						echo "The stopwatch is not running~" > "$in"
						echo "Use .stopwatch start to start the stopwatch~" > "$in"
					fi
				fi
				;;
			# TODO: Make output pretty
			# TODO: Add quotes
			# TODO: Can't this be done simpler? (external tool maybe)
			".time until "*)
				word="$(echo "$msg" | cut -d " " -f 3-)"
	
				seconds=$(echo "$(date -d "$word" +"%s")-$(date +"%s")" | bc)
				minutes=$(echo "$seconds/60" | bc)
				hours=$(echo "$minutes/60" | bc)
				days=$(echo "$hours/24" | bc)

				seconds=$(echo "$seconds-$minutes*60" | bc)
				minutes=$(echo "$minutes-$hours*60" | bc)
				hours=$(echo "$hours-$days*60" | bc)

				daysword=" days, "
				hoursword=" hours, "
				minutesword=" minutes and "

				if [[ $days -eq 1 ]]; then
					daysword=" day, "
				fi
				if [[ $hours -eq 1 ]]; then
					hoursword=" hour, "
				fi
				if [[ $minutes -eq 1 ]]; then
					minutesword=" minute and"
				fi

				if [[ $days -le 0 ]]; then
					days=""
					daysword=""
					if [[ $hours -le 0 ]]; then
						hours=""
						hoursword=""
						if [[ $minutes -le 0 ]]; then
							minutes=""
							minutesword=""
							if [[ $seconds -le 0 ]]; then
								seconds=""
							fi
						fi
					fi
				fi

				echo "$day$daysword$hours$hoursword$minutes$minutesword$seconds seconds until $word~" > "$in"
				;;
			.time)
				current="$(date +"%I:%M %p")"
			
				echo "The time is $current~"
				;;
		esac
	fi

done > "$in"
