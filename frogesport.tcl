###########################################################################
### Frogesport                                                          ###
###########################################################################
###
#
#    Copyright 2011-2014 Zmegolaz <zmegolaz@kaizoku.se>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###########################################################################
###            You don't need to edit anything in this file.            ###
###########################################################################

# Create the bindings
# Admin commands
bind pub * "!answer" ::frogesport::answer
bind pub * "!check" ::frogesport::check
bind pub * "!clear" ::frogesport::clear
bind pub * "!pause" ::frogesport::clear
bind pub * "!continue" ::frogesport::continue
bind pub * "!punish" ::frogesport::punish
bind pub * "!reward" ::frogesport::reward
bind pub * "!startmess" ::frogesport::startmess
bind pub * "!startquiz" ::frogesport::startquiz
bind pub * "!stopmess" ::frogesport::stopmess
bind pub * "!stopquiz" ::frogesport::stopquiz
# Admin commands from PM
bind msg * "addq" ::frogesport::msgaddq
bind msg * "checkq" ::frogesport::msgcheckq
bind msg * "checku" ::frogesport::msgchecku
bind msg * "delq" ::frogesport::msgdelq
bind msg * "help" ::frogesport::msghelp
bind msg * "hjälp" ::frogesport::msghelp
bind msg * "modq" ::frogesport::msgmodq
bind msg * "modu" ::frogesport::msgmodu
bind msg * "newseason" ::frogesport::msgnewseason
bind msg * "rapporter" ::frogesport::msgreports
bind msg * "rapport" ::frogesport::msgreports
bind msg * "recs" ::frogesport::msgrecs
bind msg * "reports" ::frogesport::msgreports
bind msg * "report" ::frogesport::msgreports
bind msg * "updateclasses" ::frogesport::msgupdateclasses

# User commands
bind pub * "!addq" ::frogesport::recommendq
bind pub * "!clearqueue" ::frogesport::clearqueue
bind pub * "!compare" ::frogesport::compare
bind pub * "!jämför" ::frogesport::compare
bind pub * "!comparetot" ::frogesport::comparetot
bind pub * "!jämförtot" ::frogesport::comparetot
bind pub * "!help" ::frogesport::help
bind pub * "!hjälp" ::frogesport::help
bind pub * "!queue" ::frogesport::queueques
bind pub * "!köa" ::frogesport::queueques
bind pub * "!stats" ::frogesport::stats
bind pub * "!magi" ::frogesport::spell
bind pub * "!ping" ::frogesport::ping
bind pub * "!recommend" ::frogesport::recommendq
bind pub * "!rensakö" ::frogesport::clearqueue
bind pub * "!report" ::frogesport::report
bind pub * "!spell" ::frogesport::spell
bind pub * "!suggest" ::frogesport::recommendq
bind pub * "!föreslå" ::frogesport::recommendq
bind pub * "!förslag" ::frogesport::recommendq
bind pub * "!hof" ::frogesport::hof
bind pub * "!hofarmesnitt" ::frogesport::topclantotalaverage
bind pub * "!hofarme" ::frogesport::topclantotal
bind pub * "!hofclan" ::frogesport::topclantotal
bind pub * "!hofclanavg" ::frogesport::topclantotalaverage
bind pub * "!tid" ::frogesport::time
bind pub * "!time" ::frogesport::time
bind pub * "!top10" ::frogesport::top10
bind pub * "!topfast" ::frogesport::topfast
bind pub * "!top10arme" ::frogesport::topclanseason
bind pub * "!top10armesnitt" ::frogesport::topclanseasonaverage
bind pub * "!top10clan" ::frogesport::topclanseason
bind pub * "!top10clanavg" ::frogesport::topclanseasonaverage
bind pub * "!toptid" ::frogesport::topfast
bind pub * "!topkpm" ::frogesport::topkpm
bind pub * "!version" ::frogesport::version
# User commands from PM
bind msg * "arme" ::frogesport::msgclan
bind msg * "armé" ::frogesport::msgclan
bind msg * "clan" ::frogesport::msgclan
bind msg * "clearqueue" ::frogesport::msgclearqueue
bind msg * "recommend" ::frogesport::msgrecommendq
bind msg * "suggest" ::frogesport::msgrecommendq
bind msg * "föreslå" ::frogesport::msgrecommendq
bind msg * "förslag" ::frogesport::msgrecommendq
bind msg * "köa" ::frogesport::msgqueueques
bind msg * "queue" ::frogesport::msgqueueques
bind msg * "rensakö" ::frogesport::msgclearqueue

# We need the mysqltcl package
package require mysqltcl

namespace eval ::frogesport {
	variable version "1.8 Beta6"
	
	# Include the config file
	if {[file exists scripts/frogesport/frogesport-config.tcl]} {
		source scripts/frogesport/frogesport-config.tcl
	} else {
		putlog "Frogesport not loaded: You have to create a config file! Check the example."
		return
	}

	# Disconnect and reconnect to the database. A kind of cleanup/reset of the connection, if the database for some reason has gone.
	proc checkdb { } {
		if {[info exists ::frogesport::mysql_conn]} {
			::mysql::close $::frogesport::mysql_conn
			unset ::frogesport::mysql_conn
		}
		variable mysql_conn [::mysql::connect -db $::frogesport::mysql_dbname -host $::frogesport::mysql_host -user $::frogesport::mysql_user -password $::frogesport::mysql_pass -encoding "iso8859-1"]
	}
	checkdb

	# Run some configuration checks
	if {$::frogesport::s_close_behind > [expr $::frogesport::s_question_time-1]} {
		variable s_close_behind [expr $::frogesport::s_question_time-1]
	}
	
	# All times are supposed to be in ms
	variable question_time [expr $::frogesport::s_question_time*1000]
	variable clue_time [expr $::frogesport::s_clue_time*1000]
	variable time_answer [expr $::frogesport::s_time_answer*1000]
	variable pinginterval [expr $::frogesport::s_pinginterval*1000]
	variable close_behind [expr $::frogesport::s_close_behind*1000]
	
	# Bot ID should be only the decimals of the configured ID was divided by 100000
	if {$::frogesport::i_bot_id < 0 || $::frogesport::i_bot_id > 99999} {
		putlog "Frogesport not loaded: Invalid bot ID."
		return
	}
	variable bot_id [format "%05d" $::frogesport::i_bot_id]

	# Fix percent if someone set it with a % sign
	variable clue_percent [string map {"%" ""} $::frogesport::clue_percent]

	# Set and fix some variables
	variable season_code ""
	if {![info exists quesqueue]} {
		variable quesqueue ""
	}

	# Load ::frogesport::admins and ::frogesport::prizes
	variable dbadmins [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick FROM users WHERE user_class=0" -list]
	variable prizes [::mysql::sel $::frogesport::mysql_conn "SELECT * FROM prizes" -list]

	# Remember the classes
	variable classes [::mysql::sel $::frogesport::mysql_conn "SELECT * FROM classes" -list]

	# procedure to authenticate admins
	proc checkauth { nick } {
		switch $::frogesport::auth_method {
			"1" {
				# Check if the user is op in the channel and if the user is class 0 in the database 
				if {[isop $nick $::frogesport::running_chan] && [lsearch -nocase $::frogesport::dbadmins $nick] != "-1"} {
					return 1
				}
			}
			"2" {
				# Check if the user is op in the channel and is in the configured list of admins
				if {[isop $nick $::frogesport::running_chan] && [lsearch -nocase $::frogesport::admins $nick] != "-1"} {
					return 1
				}
			}
			"3" {
				# Check if the user is op in the admin channel
				if {[isop $nick $::frogesport::admin_chan]} {
					return 1
				}
			}
			default {
				putlog "Incorrect authentication method"
			}
		}
		# If the authentication method chosen didn't return 1, return 0
		return 0
	}

	# Procedure to check the class of all users
	proc msgupdateclasses { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_class=(SELECT cid FROM classes WHERE clas_points<=user_points_total ORDER BY clas_points DESC LIMIT 1) WHERE user_class!='0'"
		if {$nick != ""} {
			putserv "PRIVMSG $nick :Alla användares klasser stämmer nu."
		}
	}

	# Update all users classes on rehash or startup. We have to put it here, since the procedure have to be defined before we can call it
	msgupdateclasses "" "" "" ""

	# Send a message every half hour, maybe to tell people why the bot is stopped
	proc startmess { nick host hand chan arg } {
		if {![checkauth $nick]} {
			return
		}
		if {[llength $arg] < 2} {
			putserv "NOTICE $nick :!startmess <intervall> <meddelande>"
			return
		}
		# Stop the previous message if it's already running
		if {[info exists ::frogesport::messageId]} {
			after cancel $::frogesport::messageId
		}
		# How often? In minutes.
		variable s_periodic_message [lindex $arg 0]
		# What should the message be?
		variable periodic_message [lrange $arg 1 end]
		sendmess
	}

	proc sendmess {} {
		putserv "PRIVMSG $::frogesport::running_chan :$::frogesport::periodic_message"
		variable messageId [after [expr $::frogesport::s_periodic_message*60000] ::frogesport::sendmess]
	}

	proc stopmess { nick host hand chan arg } {
		if {![checkauth $nick]} {
			return
		}
		after cancel $::frogesport::messageId
	}

	# Start the bot
	proc startquiz { nick host hand chan arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		if {![string equal -nocase $chan $::frogesport::running_chan]} {
			putserv "PRIVMSG $chan :\003${::frogesport::color_text},${::frogesport::color_background}Det här är inte kanalen som boten är confad att köras i!"
			return
		}
		# We won't start the quiz if it's already running
		if {[info exists ::frogesport::is_running] && $::frogesport::is_running} {
			putserv "PRIVMSG $chan :\003${::frogesport::color_text},${::frogesport::color_background}Boten körs redan i $::frogesport::running_chan!"
			return
		}
		# Restart the temporary ID counter
		variable cur_temp_id 0
		# Remember that we are running
		variable is_running 1
		# Create or empty the previous winner variable
		variable currentcorrect ""
		# Clear all the temporary IDs in the database for this bot ID
		::mysql::exec $::frogesport::mysql_conn "UPDATE questions SET ques_tempid='0.0' WHERE ques_tempid LIKE '%[::mysql::escape $::frogesport::mysql_conn $::frogesport::bot_id]'"
		# Binding for detecting answers (matches everything)
		bind pubm * {*} ::frogesport::checkanswer
		# Ask the first question
		askquestion
	}
	
	# Clear the question queue.
	proc clearqueue { nick host hand chan arg } {
		msgclearqueue $nick $host $hand $arg $chan
	}
	
	proc msgclearqueue { nick host hand arg {sendto ""} } {
		# Where should we send the replies?
		if {$sendto == ""} {
			set sendto $nick
		}
		# Check if the user is allowed to clear the queue.
		switch $::frogesport::queueques_who {
			0 {
				return
			}
			1 {
				if {![checkauth $nick]} {
					return
				}
			}
			2 {
				if {![checkauth $nick] && ![isop $nick $::frogesport::running_chan]} {
					return
				}
			}
			3 {
				if {![checkauth $nick] && ![isop $nick $::frogesport::running_chan] && ![isvoice $nick $::frogesport::running_chan]} {
					return
				}
			}
		}
		set ::frogesport::quesqueue ""
		putserv "PRIVMSG $sendto :\003${::frogesport::color_text},${::frogesport::color_background}Frågekön rensad."
	}
	
	# Put specific questions in the queue
	proc queueques { nick host hand chan arg } {
		msgqueueques $nick $host $hand $arg $chan
	}
	
	proc msgqueueques { nick host hand arg {sendto ""} } {
		# Where should we send the replies?
		if {$sendto == ""} {
			set sendto $nick
		}
		
		# Check if the user is allowed to add questions.
		# 0: Nobody.
		# 1: Admins (see auth_method above.)
		# 2: OPs and admins.
		# 3: Voiced users, OPs and admins.
		# 4: Anyone.
		switch $::frogesport::queueques_who {
			0 {
				return
			}
			1 {
				if {![checkauth $nick]} {
					return
				}
			}
			2 {
				if {![checkauth $nick] && ![isop $nick $::frogesport::running_chan]} {
					return
				}
			}
			3 {
				if {![checkauth $nick] && ![isop $nick $::frogesport::running_chan] && ![isvoice $nick $::frogesport::running_chan]} {
					return
				}
			}
		}
		
		# Check if the question queue is too long.
		if {[llength $::frogesport::quesqueue] >= $::frogesport::queueques_num} {
			putserv "PRIVMSG $sendto :\003${::frogesport::color_text},${::frogesport::color_background}Ingen fråga tillagd, kön är full."
			return
		}
		
		# Time to process the arguments.
		if {[llength [split $arg]] == 1} {
			# Only one argument.
			if {[regexp "^\[0-9\]+\$" $arg]} {
				# That argument is numerical, so just put that ID in the queue and return.
				lappend ::frogesport::quesqueue [split $arg]
				putserv "PRIVMSG $sendto :\003${::frogesport::color_text},${::frogesport::color_background}En fråga köad."
				return
			}
		}
		
		# There are more than one argument, or that one argument is non numerical.
		if {[regexp "^\[0-9\]+\$" [lindex [split $arg] 0]]} {
			set numques [lindex [split $arg] 0]
			# Remove the number from the argument.
			set arg [lrange [split $arg] 1 end]
		} else {
			# If we don't have any number, we should add 1/3 of the maximum queue length.
			set numques [expr int(ceil($::frogesport::queueques_num/3))]
		}
		
		# Check if we're allowed to add this many questions to the queue.
		if {$numques > $::frogesport::queueques_num - [llength $::frogesport::quesqueue]} {
			set numques [expr $::frogesport::queueques_num - [llength $::frogesport::quesqueue]]
		}
		
		# The first argument is (now) non numerical and what we should search for.
		switch $::frogesport::queueques_searchwhere {
			1 {
				set tempques [::mysql::sel $::frogesport::mysql_conn "SELECT qid FROM questions WHERE ques_category LIKE '%[::mysql::escape $::frogesport::mysql_conn $arg]%' ORDER BY RAND() LIMIT $numques" -list]
			}
			2 {
				set tempques [::mysql::sel $::frogesport::mysql_conn "SELECT qid FROM questions WHERE ques_question LIKE '%[::mysql::escape $::frogesport::mysql_conn $arg]%' ORDER BY RAND() LIMIT $numques" -list]
			}
			3 {
				set tempques [::mysql::sel $::frogesport::mysql_conn "SELECT qid FROM questions WHERE ques_category LIKE '%[::mysql::escape $::frogesport::mysql_conn $arg]%' OR ques_question LIKE '%[::mysql::escape $::frogesport::mysql_conn $arg]%' ORDER BY RAND() LIMIT $numques" -list]
			}
		}
		switch [llength $tempques] {
			0 {
				putserv "PRIVMSG $sendto :\003${::frogesport::color_statsnumber},${::frogesport::color_background}Inga\003${::frogesport::color_text} frågor hittade."
			}
			1 {
				putserv "PRIVMSG $sendto :\003${::frogesport::color_statsnumber},${::frogesport::color_background}En\003${::frogesport::color_text} fråga köad."
				lappend ::frogesport::quesqueue {*}$tempques
			}
			default {
				putserv "PRIVMSG $sendto :\003${::frogesport::color_statsnumber},${::frogesport::color_background}[llength $tempques]\003${::frogesport::color_text} frågor köade."
				lappend ::frogesport::quesqueue {*}$tempques
			}
		}
	}
	
	# Ask a question
	proc askquestion { } {
		# Set the current temporary ID
		variable cur_temp_id [expr $::frogesport::cur_temp_id+1]
		# Check if we have a question in the question queue.
		set question ""
		while {[llength $::frogesport::quesqueue] && $question == ""} {
			set question [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT qid, ques_category, ques_question FROM questions WHERE qid='[lindex $::frogesport::quesqueue 0]'" -list] 0]
			# Remove the question we just got from the queue.
			set ::frogesport::quesqueue [lrange $::frogesport::quesqueue 1 end]
		}
		# OK, if we didn't get a question from the queue, get one at random.
		if {$question == ""} {
			# Get the number of questions we have and multiply it by a random number to get a random offset
			set offset [::mysql::sel $::frogesport::mysql_conn "SELECT floor(RAND() * COUNT(*)) from questions" -list]
			# Get the question, use the previous offset to get a random one
			set question [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT qid, ques_category, ques_question FROM questions LIMIT [lindex $offset 0],1" -list] 0]
		}
		# Set the temporary ID on the question in the database
		::mysql::exec $::frogesport::mysql_conn "UPDATE questions SET ques_tempid='$::frogesport::cur_temp_id.$::frogesport::bot_id' WHERE qid='[lindex $question 0]'"
		# Get the answers, the default ones first if there are any, otherwise a random order.
		variable answers [::mysql::sel $::frogesport::mysql_conn "SELECT answ_answer FROM answers WHERE answ_question='[lindex $question 0]' ORDER BY answ_prefer DESC, RAND()" -flatlist]
		# Ask the question
		putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_text},${::frogesport::color_background}\037$::frogesport::cur_temp_id\037: [lindex $question 1]: [lindex $question 2]"
		# Remember the permanent ID of the question for later use.
		variable cur_perm_id [lindex $question 0]
		# The current question is not answered
		variable answered 0
		# Set current time, to be able to measure the time it took for the user to answer
		variable question_start_time [clock clicks -milliseconds]
		# Start the clue timer
		variable c_after_id [after $::frogesport::clue_time ::frogesport::giveclue]
		# Set the question timeout
		variable q_after_id [after $::frogesport::time_answer ::frogesport::nocorrect]
	}

	proc giveclue { {answer ""} {clue_number 0} } {
		# Check if we should continue on a previous clue
		if { $answer == "" } {
			# Set the answer to the first one. They are in the correct order from the SQL query
			set answer [lindex $::frogesport::answers 0]
		}
		# Split it in words
		# Check if the clue is four digits, these should have a special clue
		if {[string length $answer] == "4" && [string is integer $answer]} {
			set maskedclue "[string index $answer 0]_[string index $answer 2]_"
		} else {
			set words [split $answer]
			foreach word $words {
				# Count the letters
				set letters [string length $word]
				# Determine the number of characters to keep
				set keepchars [expr int($letters*[lindex $::frogesport::clue_percent $clue_number]/100)]
				# Create the word
				set maskedword [string range $word 0 $keepchars][string repeat "_" [expr $letters-$keepchars-1]]
				if {[string length $maskedword] == 1} {
					set maskedword "_"
				}
				lappend maskedclue $maskedword
			}
			# Join the list to one string
			set maskedclue [join $maskedclue]
		}
		# Send it
		putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_text},${::frogesport::color_background}Ledtråd: $maskedclue"
		# Check if we have more clues planned
		if {[llength $::frogesport::clue_percent] > [expr $clue_number+1]} {
			variable c_after_id [after $::frogesport::clue_time [list ::frogesport::giveclue $answer [expr $clue_number+1]]]
		}
	}

	proc nocorrect { } {
		# Should the bot tell all the correct answers?
		set correctanswer ""
		if {$::frogesport::give_answer == "1"} {
			if {[llength $::frogesport::answers] > 1} {
				set correctanswer " De rätta svaren var: [join $::frogesport::answers ", "]"
			} else {
				set correctanswer " Det rätta svaret var: [join $::frogesport::answers ", "]"
			}
		}
		# No one can get a correct answer for this.
		variable answered 1
		# Start the close behind timer if it's enabled.
		if {$::frogesport::s_close_behind} {
			variable close_behind_time [clock clicks -milliseconds]
			variable close_behind_id [after $::frogesport::close_behind ::frogesport::closebehind]
			# Remember that we are collecting nicks
			variable close_behind_collecting 1
			# Noone answered correctly, everyone is eligeble to be second
			variable last_correct_nick ""
			# We have to set this here to be able to search this list later
			variable correct_close_nick ""
		}
		# If someone for some reason set the clue timer higher than the answer time, clear the clue timer
		after cancel $::frogesport::c_after_id
		# Tell everyone the time is up
		putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_text},${::frogesport::color_background}Ingen svarade rätt inom $::frogesport::s_time_answer sekunder.$correctanswer"
		# Start the timer for the next question
		variable nq_after_id [after $::frogesport::question_time ::frogesport::askquestion]
		# If someone had a streak, they don't anymore
		variable currentcorrect ""
	}

	proc checkanswer { nick host hand chan arg } {
		# If we're not running but the bind for some reason is still here, unbind it. This should never happen.
		if {!$::frogesport::is_running} {
			catch { unbind pubm * {*} ::frogesport::checkanswer }
			return
		}
		set origarg [string trim $arg]
		# Replace *, ?, [ and ] with the escaped characters
		set arg [string map { "*" "\\\*" "?" "\\\?" "\[" "\\\[" "\]" "\\\]" } [string trim $arg]]
		# Check if the answer was correct
		if {[info exists ::frogesport::answers] && [lsearch -nocase $::frogesport::answers $arg] >= 0} {
			# Check whether or not this is the first correct answer
			if {$::frogesport::answered} {
				# Remember the nick if the close behind feature is enabled, we're collecting nicks, it's this users first close behind answer and the user wasn't the first answerer
				if {$::frogesport::s_close_behind && $::frogesport::close_behind_collecting && [lsearch $::frogesport::correct_close_nick $nick] < 0 && $nick != $::frogesport::last_correct_nick} {
					if {![info exists ::frogesport::correct_close]} {
						variable correct_close ""
					}
					lappend ::frogesport::correct_close_nick $nick
					lappend ::frogesport::correct_close_time [expr double([clock clicks -milliseconds]-$::frogesport::close_behind_time)/1000]
				}
			} else {
				# Check if the user answered a question in another channel a short while ago
				# Get new user information
				set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass, user_lastactive_chan, user_kpm_max, clan_name FROM users LEFT JOIN clanmembers ON uid=clme_uid LEFT JOIN clans ON clme_clid=clid AND clme_member='yes' WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
				if {[lindex $curuser 10] != $::frogesport::running_chan && [expr [lindex $curuser 8]+$::frogesport::s_channel_switch_time] > [clock seconds]} {
					putserv "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick \003${::frogesport::color_text}hade rätt, men måste vänta [expr [lindex $curuser 8]+$::frogesport::s_channel_switch_time-[clock seconds]] sekunder till för att kunna svara i den här kanalen."
					return
				}
				set uid [lindex $curuser 0]
				# Remember that we have got a correct answer
				variable answered 1
				# How long did it take for the user to answer?
				set answertime [expr double([clock clicks -milliseconds]-$::frogesport::question_start_time)/1000]
				# How many keys per minute was that?
				set answerkpm [expr double(round(1000*([string length $origarg]/($answertime/60))))/1000]
				# Stop the pending clue and that no answer was given procedures
				after cancel $::frogesport::c_after_id
				after cancel $::frogesport::q_after_id
				# Start the close behind timer if it's enabled.
				if {$::frogesport::s_close_behind} {
					variable close_behind_time [clock clicks -milliseconds]
					variable close_behind_id [after $::frogesport::close_behind ::frogesport::closebehind]
					# Remember that we are collecting nicks
					variable close_behind_collecting 1
					# Remember who answered correctly
					variable last_correct_nick $nick
					# Empty some variables
					variable correct_close_nick ""
					variable correct_close_time ""
				}
				# Is this a new user?
				if {$curuser == ""} {
					# We have a new user!
					::mysql::exec $::frogesport::mysql_conn "INSERT INTO users (user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_lastactive_chan, user_kpm_max)\
						VALUES ('[::mysql::escape $::frogesport::mysql_conn $nick]', 1, 1, '$answertime', 1, 1, 1, [clock seconds], '[::mysql::escape $::frogesport::mysql_conn $::frogesport::running_chan]', '$answerkpm')"
					set uid [::mysql::insertid $::frogesport::mysql_conn]
					variable currentcorrect [list $nick "1"]
					set rankmess ""
				} else {
					# The user's been here before, check for a streak
					if {[string equal $nick [lindex $::frogesport::currentcorrect 0]]} {
						# The user is on a streak, add the user to the current streakmeater
						variable currentcorrect [list $nick [expr [lindex $::frogesport::currentcorrect 1]+1]]
					} else {
						# This use is not on a streak, reset the variable
						variable currentcorrect [list $nick "1"]
					}
					# Check if we should update the users fastest time
					set updatetime ""
					if { $answertime < [lindex $curuser 4] } {
						set updatetime ", user_time='$answertime'"
					}
					# Check if we should update the kpm record
					set updatekpmmax ""
					if { $answerkpm > [lindex $curuser 11] } {
						set updatekpmmax ", user_kpm_max='$answerkpm'"
					}
					# Check if we should update the users longest streak
					set updatestreak ""
					if { [lindex $::frogesport::currentcorrect 1] > [lindex $curuser 5] } {
						set updatestreak ", user_inarow='[lindex $::frogesport::currentcorrect 1]'"
					}
					# Check if we should update the class
					set updateclass ""
					set updatemana ""
					if {[lsearch -index 1 $::frogesport::classes [expr [lindex $curuser 3]+1]] >= 0 && [lindex $curuser 7] != "0"} {
						set newclass [::mysql::sel $::frogesport::mysql_conn "SELECT * FROM classes WHERE clas_points='[expr [lindex $curuser 3]+1]'" -flatlist]
						set updateclass ", user_class='[lindex $newclass 0]'"
						# We should also add mana, this isn't done in the next if statement because we still use the old class
						set updatemana ", user_mana=user_mana+1"
					}
					# Check if we should add more mana
					if {[lindex $curuser 6] < [lindex [lindex $::frogesport::classes [lindex $curuser 7]] 3]} {
						set updatemana ", user_mana=user_mana+1"
					}
					::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season+1, user_points_total=user_points_total+1, user_lastactive='[clock seconds]', user_lastactive_chan='[::mysql::escape $::frogesport::mysql_conn $::frogesport::running_chan]'$updatetime$updatestreak$updateclass$updatemana$updatekpmmax WHERE uid='$uid'"
					::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(user_points_season) FROM users WHERE user_points_season>'[expr [lindex $curuser 2]+1]'"
					set rank [expr [lindex [::mysql::fetch $::frogesport::mysql_conn] 0]+1]
					::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(user_points_season) FROM users WHERE user_points_season='[expr [lindex $curuser 2]+1]'"
					set onelessrank [lindex [::mysql::fetch $::frogesport::mysql_conn] 0]
					# Count how many users we currently have
					set totalusers [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(uid) FROM users" -list]
					set rankmess " Rank: $rank av $totalusers."
				}
				set curclass ""
				if {[info exists curuser] && $curuser != ""} {
					set curclass " \[[lindex [lindex $::frogesport::classes [lindex $curuser 7]] 2]\]"
				}
				# Check if the user has a custom class
				if {[lindex $curuser 9] != ""} {
					set curclass " \[[lindex $curuser 9]\]"
				}
				set clanname ""
				# Check if the user has a custom class
				if {[lindex $curuser 12] != ""} {
					set clanname "\[[lindex $curuser 12]\] "
				}
				# Tell everyone the time is up
				putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_text},${::frogesport::color_background}Vinnare: \003${::frogesport::color_nick}$nick\003${::frogesport::color_class}$curclass $clanname\003${::frogesport::color_text}Svar: \003${::frogesport::color_answer}$origarg \003${::frogesport::color_text}Tid: [string map {, . . ,} ${answertime}]s. KPM: [string map {, . . ,} ${answerkpm}] I rad: [lindex $::frogesport::currentcorrect 1]. Säsongspoäng: [expr [lindex $curuser 2]+1].$rankmess Total poäng: [expr [lindex $curuser 3]+1]."
				if {[info exists updateclass] && $updateclass != ""} {
					putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick\003${::frogesport::color_text} har gått upp till level [lindex $newclass 0] och är nu rankad som [lindex $newclass 2]! [lindex $newclass 4]"
				}
				# If the user gained a rank, tell everyone
				if {[info exists onelessrank] && $onelessrank > 1} {
					putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick \003${::frogesport::color_text}har stigit i ranking: $rank av $totalusers."
				}
				# If the user gained a prize, tell everyone
				if {[set prize [lsearch -inline -all -index 1 $::frogesport::prizes [lindex $::frogesport::currentcorrect 1]]] != ""} {
					# If there's multiple answers, choose one at random
					set randprize [lindex [lindex $prize [expr int([llength $prize]*rand())]] 2]
					putserv "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick \003${::frogesport::color_text}har svarat rätt \003${::frogesport::color_statsnumber}[lindex $::frogesport::currentcorrect 1]\003${::frogesport::color_text} gånger i rad och får $randprize som pris!"
				}
				# If we're configured to do so, save the answer.
				if {[string is true $::frogesport::save_answers]} {
					::mysql::exec $::frogesport::mysql_conn "INSERT INTO correctanswers (coan_qid, coan_uid, coan_channel, coan_answer, coan_time, coan_date)\
						VALUES ('$::frogesport::cur_perm_id', '$uid', '[::mysql::escape $::frogesport::mysql_conn $::frogesport::running_chan]', \
						'[::mysql::escape $::frogesport::mysql_conn $origarg]', '$answertime', UNIX_TIMESTAMP(NOW()))"
				}
				# Start the timer for the next question
				variable nq_after_id [after $::frogesport::question_time ::frogesport::askquestion]
			}
		}
	}

	# Tell the users how far behind they were
	proc closebehind { } {
		# We are no longer collecting nicks
		variable close_behind_collecting 0
		# Check if there are any users who are close behind
		if {[info exists ::frogesport::correct_close_nick]} {
			set num_nicks [llength $::frogesport::correct_close_nick]
			for {set i 0} {$i<$num_nicks} {incr i} {
				lappend output "\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $::frogesport::correct_close_nick $i] \003${::frogesport::color_text}var \003${::frogesport::color_statsnumber}[string map {, . . ,} [lindex $::frogesport::correct_close_time $i]]\003${::frogesport::color_text} sekunder efter"
			}
			putserv "PRIVMSG $::frogesport::running_chan :[join $output ", "]."
			unset $::frogesport::correct_close_nick
			unset $::frogesport::correct_close_time
		}
	}

	proc stopquiz { nick host hand chan arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# If the is_running variable doesn't exist or is 0, the bot isn't running
		if {![info exists ::frogesport::is_running] || !$::frogesport::is_running} {
			# Just in case, clear all pending after commands.
			foreach i [split [after info]] {
				after cancel $i
			}
			return
		}
		# We're not running anymore
		variable is_running 0
		variable cur_temp_id 0
		# Unbind the answer checker to save CPU cycles
		catch { unbind pubm * {*} ::frogesport::checkanswer }
		# Clear all pending after commands.
		foreach i [split [after info]] {
			after cancel $i
		}
		putnow "PRIVMSG $::frogesport::running_chan :\003${::frogesport::color_text},${::frogesport::color_background}Slut! :("
	}

	# Clear all pending "after" commands, should never have to be used
	proc clear { nick host hand chan arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		set running [split [after info]]
		foreach i $running {
			after cancel $i
		}
		variable is_running 0
		# Unbind the answer checker to save CPU cycles
		catch { unbind pubm * {*} ::frogesport::checkanswer }
	}

	# If the bot has stopped for some reason, it should be possible to just continue without having to restarting it
	proc continue { nick host hand chan arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Check if the current id exists
		if {![info exists ::frogesport::cur_temp_id] || !$::frogesport::cur_temp_id} {
			putserv "PRIVMSG $chan :\003${::frogesport::color_text},${::frogesport::color_background}Det finns inget att fortsätta på!"
			return
		}
		# Clear all pending after commands, in case the command was used when it wasn't needed. This effectively just cancels the current question and starts a new one
		set running [split [after info]]
		foreach i $running {
			after cancel $i
		}
		# Fix some variables
		variable is_running 1
		variable answers ""
		# If someone had a streak, they don't anymore
		variable currentcorrect ""
		# Binding for detecting answers (matches everything)
		bind pubm * {*} ::frogesport::checkanswer
		# Ask the next question
		askquestion
	}

	proc ping { nick host hand chan arg } {
		if {![info exist ::frogesport::lastping] || $::frogesport::lastping+$::frogesport::pinginterval < [clock clicks -milliseconds]} {
			putnow "PRIVMSG $chan :$nick: Pong!"
			variable lastping [clock clicks -milliseconds]
		}
	}

	proc stats { nick host hand chan arg } {
		set user [lindex [split $arg] 0]
		# Check if we have an argument (not with eachother, not that type of argument), if not, use the users nick
		if {$user == ""} {
			set user $nick
		}
		# Get info about the current user
		set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass, user_kpm_max FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]' LIMIT 1" -list] 0]
		# Check if the user exists
		if {$curuser == ""} {
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}$user har inte svarat rätt på någon fråga än."
			return
		}
		# Count the number of users in the database
		set totalusers [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(uid) FROM users" -list]
		# Count the number of users before the current user
		set usersabove [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(user_points_season) FROM users WHERE user_points_season>'[lindex $curuser 2]'" -list]
		# Get info about the user above the current one
		set aboveuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT `user_nick`,`user_points_season` FROM `users` WHERE `user_points_season`=(SELECT MIN(`user_points_season`) FROM `users`WHERE `user_points_season`>'[lindex $curuser 2]') LIMIT 1" -list] 0]
		# Check if we're in the lead
		if {$aboveuser != ""} {
			set pointsfrom "\003${::frogesport::color_statsnumber}[expr [lindex $aboveuser 1]-[lindex $curuser 2]]\003${::frogesport::color_text} poäng ifrån \003${::frogesport::color_nick}[lindex $aboveuser 0]"
		} else {
			set pointsfrom "\003${::frogesport::color_nick}[lindex $curuser 1]\003${::frogesport::color_text} leder!"
		}
		# Check if the user has a custom class
		if {[set curclass [lindex $curuser 9]] == ""} {
			set curclass [lindex [lindex $::frogesport::classes [lsearch -index 0 $::frogesport::classes [lindex $curuser 7]]] 2]
		}
		# Check if we have a date for the current user
		set lastpoint ""
		if {[lindex $curuser 8]} {
			set lastpoint "Senaste poäng: \003${::frogesport::color_statsnumber}[clock format [lindex $curuser 8] -format "%Y-%m-%d %H:%M:%S"]\003${::frogesport::color_text}. "
		}
		putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Statistik för \003${::frogesport::color_nick}[lindex $curuser 1]\003${::frogesport::color_text}:\
			Snabbaste tid: \003${::frogesport::color_statsnumber}[string map {, . . ,} [lindex $curuser 4]]\003${::frogesport::color_text} sekunder.\
			Bästa streak: \003${::frogesport::color_statsnumber}[lindex $curuser 5]\003${::frogesport::color_text}.\
			Högsta KPM: \003${::frogesport::color_statsnumber}[string map {, . . ,} [lindex $curuser 10]]\003${::frogesport::color_text}.\
			Säsongspoäng: \003${::frogesport::color_statsnumber}[lindex $curuser 2]\003${::frogesport::color_text}.\
			Total poäng: \003${::frogesport::color_statsnumber}[lindex $curuser 3]\003${::frogesport::color_text}.\
			Klass: \003${::frogesport::color_class}$curclass\003${::frogesport::color_text}.\
			Level: \003${::frogesport::color_statsnumber}[lindex $curuser 7]\003${::frogesport::color_text}.\
			Mana: \003${::frogesport::color_statsnumber}[lindex $curuser 6]\003${::frogesport::color_text}.\
			Rankad: \003${::frogesport::color_statsnumber}[expr [lindex $usersabove 0]+1]\003${::frogesport::color_text} av \003${::frogesport::color_statsnumber}[lindex $totalusers 0]\003${::frogesport::color_text}.\
			$lastpoint$pointsfrom"
	}

	proc spell { nick host hand chan arg } {
		# Get info about the current user
		set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
		# Check if the user exists
		if {$curuser == ""} {
			# Notify user and return
			putserv "NOTICE $nick :Ditt nick finns inte i databasen."
			return
		}
		# Check if the user has the required level to use spells, class 0 is God.
		if {[lindex $curuser 7] < $::frogesport::spell_level && [lindex $curuser 7] != "0"} {
			# Notify user and return
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du måste vara level \003${::frogesport::color_statsnumber}$::frogesport::spell_level\003${::frogesport::color_text} för att använda magier, du är bara på \003${::frogesport::color_statsnumber}[lindex $curuser 7]"
			return
		}
		set spell [lindex [split $arg] 0]
		# Set some notification variables
		set helpvar "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Användning av !spell:\
			!spell answer (få svaret på den nuvarande frågan, kostar $::frogesport::cost_answer mana),\
			!spell steal <\003${::frogesport::color_nick}användare\003${::frogesport::color_text}> (stjäl $::frogesport::steal_points poäng, kostar $::frogesport::cost_steal mana),\
			!spell give <\003${::frogesport::color_nick}nick\003${::frogesport::color_text}> (ge $::frogesport::give_points points, kostar $::frogesport::cost_give mana),\
			!spell prevanswer <id> (få svaret på en tidigare fråga, kostar $::frogesport::cost_prevanswer mana),\
			!spell setvoice (ger dig voice (+v), kostar $::frogesport::cost_setvoice mana)"
		set lowmana "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du har inte tillräckligt med mana!"
		# Get the user, if any
		set user [lindex [split $arg] 1]
		switch -glob $spell {
			"sno" -
			"steal" {
				# Check if the user told us who to steal from
				if {$user == ""} {
					putserv $helpvar
				} elseif {![string compare -nocase $user $nick]} {
					putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du kan inte stjäla poäng ifrån dig själv!"
				} else {
					# If the user has less than ::frogesport::cost_steal mana, he's not allowed to steal
					if {[lindex $curuser 6] < $::frogesport::cost_steal} {
						putserv $lowmana
					} else {
						# Get info about the user who's being robbed
						set robbeduser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]' LIMIT 1" -list] 0]
						# If the robbed user has less than ::frogesport::steal_points points, steal only them
						if {[lindex $robbeduser 2] < $::frogesport::steal_points} {
							set stealpoints [lindex $robbeduser 2]
						} else {
							set stealpoints $::frogesport::steal_points
						}
						# We don't need to check for class advancements since this only affects the season points and classes are based on total points
						# Remove points from the robbed user and add them to the robber, and remove mana from the robber
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season-$stealpoints WHERE uid='[lindex $robbeduser 0]' LIMIT 1"
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season+$stealpoints, user_mana=user_mana-$::frogesport::cost_steal WHERE uid='[lindex $curuser 0]' LIMIT 1"
						# Tell everyone and notify the stealer that the deed is done
						putserv "PRIVMSG $chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick\003${::frogesport::color_text} stal $stealpoints poäng från \003${::frogesport::color_nick}$user"
						putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du stal \003${::frogesport::color_statsnumber}$stealpoints\003${::frogesport::color_text} poäng från \003${::frogesport::color_nick}$user\003${::frogesport::color_text},${::frogesport::color_background}, [expr [lindex $curuser 6]-$::frogesport::cost_steal] mana kvar."
					}
				}
			}
			"ge" -
			"give" {
				# Check if the user told us who to give to
				if {$user == ""} {
					putserv $helpvar
				} elseif {![string compare -nocase $user $nick]} {
					putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du kan inte ge dig själv poäng!"
				} else {
					# Get info about the current user
					set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
					# If this user has less than ::frogesport::cost_steal mana, it's not allowed to steal
					if {[lindex $curuser 6] < $::frogesport::cost_give} {
						putserv $lowmana
					} else {
						# Get info about the user who's being given points
						set givenuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]' LIMIT 1" -list] 0]
						# If the giving user has less than ::frogesport::give_points points, give only that ammount
						if {[lindex $curuser 2] < $::frogesport::give_points} {
							set givepoints [lindex $curuser 2]
						} else {
							set givepoints $::frogesport::give_points
						}
						# We don't need to check for class advancements since this only affects the season points, and classes are based on total points
						# Remove points from the giving user and add them to the lycky one, and remove mana from the giver
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season+$givepoints WHERE uid='[lindex $givenuser 0]' LIMIT 1"
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season-$givepoints, user_mana=user_mana-$::frogesport::cost_give WHERE uid='[lindex $curuser 0]' LIMIT 1"
						# Tell everyone and notify the stealer that the deed is done
						putserv "PRIVMSG $chan :\003${::frogesport::color_nick},${::frogesport::color_background}$nick\003${::frogesport::color_text} gav $givepoints poäng till \003${::frogesport::color_nick}$user"
						putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du gav \003${::frogesport::color_statsnumber}$givepoints\003${::frogesport::color_text} poäng till \003${::frogesport::color_nick}$user\003${::frogesport::color_text},${::frogesport::color_background}, [expr [lindex $curuser 6]-$::frogesport::cost_steal] mana kvar."
					}
				}
			}
			"svar" -
			"answer" {
				# Check if there is any answer to get, there isn't if someone answered correctly on the last question
				if {![info exists ::frogesport::answers] || $::frogesport::answers == ""} {
					putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns inget svar att hämta."
				} elseif {[info exists ::frogesport::is_running] && $::frogesport::is_running} {
					# Get info about the current user
					set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
					# If this user has less than ::frogesport::cost_answer mana, it's not allowed to get the answers
					if {[lindex $curuser 6] < $::frogesport::cost_answer} {
						putserv $lowmana
					} else {
						# Create a list of the correct answers
						if {[llength [lindex $::frogesport::answers 1]]} {
							set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}De rätta svaren på fråga \003${::frogesport::color_statsnumber}$::frogesport::cur_temp_id\003${::frogesport::color_text} är: \003${::frogesport::color_answer}"
						} else {
							set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}Det rätta svaret på fråga \003${::frogesport::color_statsnumber}$::frogesport::cur_temp_id\003${::frogesport::color_text} är: \003${::frogesport::color_answer}"
						}
						append correctanswer [join $::frogesport::answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_answer}"]
						# Remove mana from the user
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_mana=user_mana-$::frogesport::cost_answer WHERE uid='[lindex $curuser 0]' LIMIT 1"
						# Give the user the correct answer(s)
						putserv "NOTICE $nick :$correctanswer"
					}
				}
			}
			"tidigaresvar" -
			"prevanswer" {
				# Check if the id is valid. ... This variable is currently named $user since it was previously only used for nicks, but oh well
				if {![regexp "^\[0-9\]+\$" $user]} {
					putserv $helpvar
					return
				}
				# Get info about the current user
				set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
				if {[lindex $curuser 6] < $::frogesport::cost_prevanswer} {
				# If this user has less than ::frogesport::cost_answer mana, it's not allowed to get the answers
					putserv $lowmana
					return
				} 
				# Check that it's a valid ID
				if {$user >= $::frogesport::cur_temp_id && !$::frogesport::answered} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du får bara svaret på tidigare frågor!"
					return
				}
				# Get the answers for the question
				set numrows [::mysql::sel $::frogesport::mysql_conn "SELECT answers.answ_answer FROM questions LEFT JOIN answers ON questions.qid=answers.answ_question WHERE questions.ques_tempid='$user.$::frogesport::bot_id'"]
				# Check if the tempid was valid
				if {$numrows == "0"} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Tyvärr var det för länge sendan den här frågan ställdes."
					return
				}
				while {[set row [::mysql::fetch $::frogesport::mysql_conn]] != ""} {
					lappend answers [lindex $row 0]
				}
				# Create a list of the correct answers
				if {[llength $answers] != "1"} {
					set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}De rätta svaren på fråga \003${::frogesport::color_statsnumber}$user\003${::frogesport::color_text} var: \003${::frogesport::color_answer}"
				} else {
					set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}Det rätta svaret på fråga \003${::frogesport::color_statsnumber}$user\003${::frogesport::color_text} var: \003${::frogesport::color_answer}"
				}
				append correctanswer [join $answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_answer}"]
				# Remove mana from the user
				::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_mana=user_mana-$::frogesport::cost_prevanswer WHERE uid='[lindex $curuser 0]' LIMIT 1"
				# Give the user the correct answer(s)
				putserv "NOTICE $nick :$correctanswer"
			}
			"voice" -
			"setvoice" {
				# Check if the user already is voiced
				if {[isvoice $nick $::frogesport::running_chan]} {
					putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du har redan voice (+v)"
				} else {
					# Get info about the current user
					set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT uid, user_nick, user_points_season, user_points_total, user_time, user_inarow, user_mana, user_class, user_lastactive, user_customclass FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
					# If this user has less than ::frogesport::cost_setvoice mana, it's not allowed to set voice
					if {[lindex $curuser 6] < $::frogesport::cost_setvoice} {
						putserv $lowmana
					} else {
						::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_mana=user_mana-$::frogesport::cost_setvoice WHERE uid='[lindex $curuser 0]' LIMIT 1"
						# Give the user voice
						putserv "MODE $::frogesport::running_chan +v $nick"
					}
				}
			}
			default {
				putserv $helpvar
			}
		}
	}

	proc report { nick host hand chan arg } {
		set tempid [lindex [split $arg] 0]
		set comment [join [lrange [split $arg] 1 end]]
		# Check that the id only contains numbers and that there is a comment
		if {![regexp "^\[0-9\]+\$" $tempid] || $comment == ""} {
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}!report <id> <kommentar> - Rapportera en fråga. Du måste ange både ID och en kommentar om varför du rapporterade den."
			return
		}
		# Check if the temporary ID that the user supplied exists
		set validid [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(ques_tempid) FROM questions WHERE ques_tempid='$tempid.$::frogesport::bot_id' LIMIT 1" -list] 0]
		if {$validid} {
			# The ID is valid, add the report and notify the user
			::mysql::exec $::frogesport::mysql_conn "INSERT INTO reports (repo_qid, repo_comment, repo_user) VALUES((SELECT qid FROM questions WHERE ques_tempid='$tempid.$::frogesport::bot_id' LIMIT 1), '[::mysql::escape $::frogesport::mysql_conn $comment]', '[::mysql::escape $::frogesport::mysql_conn $nick]')"
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Fråga $tempid rapporterad, tack!"
		} else {
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Fråga $tempid har inte ställts än, eller så var det för länge sedan."
		}
	}

	proc recommendq { nick host hand chan arg } {
		putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Användning: suggest <källa på frågan>|<kategori>|<fråga>|<svar>\[|<svar>\]... Skriv \u00A7 i början av ett svar för att använda det för att skapa ledtråden. Exempel: recommend Wikipedia-länk|Grodan|I vilken kanal körs grodan?|#grodan|grodan"
	}

	proc msgrecommendq { nick host hand arg } {
		set arg [string trim $arg "| 	"]
		set helpvar "\003${::frogesport::color_text},${::frogesport::color_background}Användning: recommend <källa på frågan>|<kategori>|<fråga>|<svar>\[|<svar>\]... Skriv \u00A7 i början av ett svar för att använda det för att skapa ledtråden. Exempel: recommend Wikipedia-länk|Grodan|I vilken kanal körs grodan?|\u00A7#grodan|grodan"
		if {[string equal -nocase "help" $arg] || [string match -nocase "hj?lp" $arg]} {
			putserv "PRIVMSG $nick :$helpvar"
			return
		}
		set args [split $arg "|"]
		set source [lindex $args 0]
		set category [lindex $args 1]
		set question [lindex $args 2]
		set answers [lrange $args 3 end]
		if {$answers == ""} {
			putserv "PRIVMSG $nick :$helpvar"
			return
		}
		::mysql::exec $::frogesport::mysql_conn "INSERT INTO recommendqs (recq_category, recq_question, recq_addedby, recq_source) VALUES('[::mysql::escape $::frogesport::mysql_conn $category]', '[::mysql::escape $::frogesport::mysql_conn $question]', '[::mysql::escape $::frogesport::mysql_conn $nick]', '[::mysql::escape $::frogesport::mysql_conn $source]')"
		# Get the ID of the question we just entered
		set rqid [::mysql::insertid $::frogesport::mysql_conn]
		foreach answer $answers {
			set prefer "0"
			if {[scan [string index $answer 0] %c]== [scan "\u00A7" %c]} {
				set answer [string range $answer 1 end]
				set prefer "1"
			}
			lappend sql_answers "('$rqid', '[::mysql::escape $::frogesport::mysql_conn $answer]', $prefer)" 
		}
		::mysql::exec $::frogesport::mysql_conn "INSERT INTO recommendas (reca_rqid, reca_answer, reca_prefer) VALUES[join $sql_answers ", "]"
		putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Tack så mycket, frågan är inlagd!"
	}

	proc msgrecs { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Get what the user wants to do
		set action [lindex [split $arg] 0]
		set value [lindex [split $arg] 1]
		# Check if the user wants help, we put it here so that we won't have to put the MySQL code in each switch block
		if {$action == "help" || [string match -nocase $arg "hj?lp"] || $arg == ""} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}recs <show|accept|delete> \[frågans id\] - Visar, tar bort och accepterar rekommenderade frågor."
			return
		}
		switch $action {
			"visa" -
			"view" -
			"show" {
				set recoms [::mysql::sel $::frogesport::mysql_conn "SELECT rqid, recq_category, recq_question, recq_addedby, recq_source FROM recommendqs ORDER BY recq_lastshow ASC, rqid DESC LIMIT [::mysql::escape $::frogesport::mysql_conn $::frogesport::recommend_show]" -list]
				set numrecoms [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(rqid) FROM recommendqs" -list] 0 0]
				if {[llength $recoms] == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Inga rekommendationer!"
					return
				}
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}De $::frogesport::recommend_show senaste rekommenderade frågorna av totalt $numrecoms:"
				foreach row $recoms {
					# Remember the IDs of all show reports
					lappend allids [lindex $row 0]
					# Get the answers
					set answerresp [::mysql::sel $::frogesport::mysql_conn "SELECT reca_answer, reca_prefer FROM recommendas WHERE reca_rqid='[::mysql::escape $::frogesport::mysql_conn [lindex $row 0]]'" -list]
					# Put the answers in a list
					set answers ""
					foreach answer $answerresp {
						# Check if the answer is preferred
						set prefered ""
						if {[lindex $answer 1] == "1"} {
							set prefered "\u00A7"
						}
						lappend answers $prefered[lindex $answer 0]
					}
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Rekommendationens ID: \003${::frogesport::color_statsnumber}[lindex $row 0]\003${::frogesport::color_text}\
						rekommenderad av: \003${::frogesport::color_nick}[lindex $row 3]\003${::frogesport::color_text}\
						Kategori: \003${::frogesport::color_answer}[lindex $row 1]\003${::frogesport::color_text}\
						Fråga: \003${::frogesport::color_answer}[lindex $row 2]\003${::frogesport::color_text}\
						Svar: \003${::frogesport::color_answer}[join $answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_answer}"]\003${::frogesport::color_text}.\
						Källa: \003${::frogesport::color_answer}[lindex $row 4]\003${::frogesport::color_text}"
				}
				::mysql::exec $::frogesport::mysql_conn "UPDATE recommendqs SET recq_lastshow=UNIX_TIMESTAMP(NOW()) WHERE rqid IN ([join $allids ", "])"
			}
			"radera" -
			"del" -
			"delete" {
				# Check if the supplied id is numeric
				if {![regexp "^\[0-9\]+\$" $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_statsnumber},${::frogesport::color_background}$value\003${::frogesport::color_text} är inte ett giltigt ID."
					return
				}
				set count [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(rqid) FROM recommendqs WHERE rqid='[::mysql::escape $::frogesport::mysql_conn $value]'" -list]
				if {![lindex $count 0]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen rekommenderad fråga med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text}."
					return
				}
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM recommendqs WHERE rqid='[::mysql::escape $::frogesport::mysql_conn $value]'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Den rekommenderade frågan med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text} borttagen!"
			}
			"acceptera" -
			"accept" {
				# Check if the supplied id is numeric
				if {![regexp "^\[0-9\]+\$" $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_statsnumber},${::frogesport::color_background}$value\003${::frogesport::color_text} är inte ett giltigt ID."
					return
				}
				set count [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(`rqid`) FROM `recommendqs` WHERE `rqid`='[::mysql::escape $::frogesport::mysql_conn $value]'" -list]
				if {![lindex $count 0]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen rekommenderad fråga med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text}."
					return
				}
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO `questions` (`ques_category`, `ques_question`) SELECT `recq_category`, `recq_question` FROM `recommendqs` WHERE `rqid`='[::mysql::escape $::frogesport::mysql_conn $value]'"
				set newid [::mysql::insertid $::frogesport::mysql_conn]
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO `answers` (`answ_question`, `answ_answer`, `answ_prefer`) SELECT '$newid', `reca_answer`, `reca_prefer` FROM `recommendas` WHERE `reca_rqid`='[::mysql::escape $::frogesport::mysql_conn $value]'"
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM `recommendqs` WHERE `rqid`='[::mysql::escape $::frogesport::mysql_conn $value]'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Den rekommenderade frågan med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text} accepterad och inlagt med permanent ID \003${::frogesport::color_statsnumber}$newid\003${::frogesport::color_text}!"
			}
			default {
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Visar tar bort och accepterar rekommenderade frågor. Användning: recs <show|delete|accept> <id>"
				return
			}
		}
	}

	proc answer { nick host hand chan arg } {
		# Only OPs are allowed to use this command, but the user doesn't have to be admin
		if {[isop $nick $::frogesport::running_chan]} {
			# Check if there is any answer to get
			if {![info exists ::frogesport::answers] || $::frogesport::answers == ""} {
				putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns inget svar att hämta."
				return
			}
			# Create a list of the correct answers
			if {[llength [lindex $::frogesport::answers 1]] > 1} {
				set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}De rätta svaren till fråga \003${::frogesport::color_statsnumber}$::frogesport::cur_temp_id\003${::frogesport::color_text} är: "
			} else {
				set correctanswer "\003${::frogesport::color_text},${::frogesport::color_background}Det rätta svaret till fråga \003${::frogesport::color_statsnumber}$::frogesport::cur_temp_id\003${::frogesport::color_text} är: "
			}
			append correctanswer "\003${::frogesport::color_answer}[join $::frogesport::answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_answer}"]"
			# Give the user the correct answer(s)
			putserv "NOTICE $nick :$correctanswer"
		}
	}

	# The hof and top10 commands are very similar, so we actually use the same procedure for them
	proc hof { nick host hand chan arg } {
		top $nick "total" 10
	}
	proc top10 { nick host hand chan arg } {
		top $nick "season" 10
	}
	proc topkpm { nick host hand chan arg } {
		top $nick "kpm" 10
	}
	proc topfast { nick host hand chan arg } {
		top $nick "fast" 10
	}
	proc topclantotal { nick host hand chan arg } {
		top $nick "clantotal" 10
	}
	proc topclanseason { nick host hand chan arg } {
		top $nick "clanseason" 10
	}
	proc topclantotalaverage { nick host hand chan arg } {
		top $nick "clantotalaverage" 10
	}
	proc topclanseasonaverage { nick host hand chan arg } {
		top $nick "clanseasonaverage" 10
	}
	proc top { nick scope number } {
		# Get the data and send a topic
		switch $scope {
			"season" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick,user_points_season FROM users ORDER BY user_points_season DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}I ledningen denna säsong:"
			}
			"total" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick,user_points_total FROM users ORDER BY user_points_total DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}I ledningen totalt:"
			}
			"kpm" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick,user_kpm_max FROM users ORDER BY user_kpm_max DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Högst antal knappar per minut:"
			}
			"fast" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick,user_time FROM users ORDER BY user_time ASC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Snabbaste svar:"
			}
			"clantotal" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT clan_name, SUM(user_points_total) AS points FROM clanmembers LEFT JOIN users ON clme_uid=uid LEFT JOIN clans ON clme_clid=clid WHERE clme_member='yes' GROUP BY clan_name ORDER BY points DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Armeer med flest totalpoäng:"
			}
			"clanseason" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT clan_name, SUM(user_points_season) AS points FROM clanmembers LEFT JOIN users ON clme_uid=uid LEFT JOIN clans ON clme_clid=clid WHERE clme_member='yes' GROUP BY clan_name ORDER BY points DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Armeer med flest säsongspoäng:"
			}
			"clantotalaverage" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT clan_name, ROUND(AVG(user_points_total), 0) AS points FROM clanmembers LEFT JOIN users ON clme_uid=uid LEFT JOIN clans ON clme_clid=clid WHERE clme_member='yes' GROUP BY clan_name ORDER BY points DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Armeer med högst snittpoäng totalt:"
			}
			"clanseasonaverage" {
				set top [::mysql::sel $::frogesport::mysql_conn "SELECT clan_name, ROUND(AVG(user_points_season), 0) AS points FROM clanmembers LEFT JOIN users ON clme_uid=uid LEFT JOIN clans ON clme_clid=clid WHERE clme_member='yes' GROUP BY clan_name ORDER BY points DESC LIMIT $number" -list]
				set topout "\003${::frogesport::color_text},${::frogesport::color_background}Armeer med högst snittpoäng för säsongen:"
			}
		}
		# Create the list with the top users
		set i 0
		foreach row $top {
			incr i
			set topout "$topout $i: \003${::frogesport::color_nick}[lindex $row 0]\003${::frogesport::color_text}(\003${::frogesport::color_statsnumber}[lindex $row 1]\003${::frogesport::color_text})"
		}
		# Output the whole thing
		putserv "NOTICE $nick :$topout"
	}
	
	proc time { nick host hand chan arg } {
		set curuser [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT user_lastactive_chan, user_lastactive FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]' LIMIT 1" -list] 0]
		if {[expr [lindex $curuser 1]+$::frogesport::s_channel_switch_time] > [clock seconds]} {
			putserv "NOTICE $nick :Du måste vänta [expr [lindex $curuser 1]+$::frogesport::s_channel_switch_time-[clock seconds]] sekunder till innan du kan svara i någon annan kanal än [lindex $curuser 0]."
		} else {
			putserv "NOTICE $nick :Ingen väntetid kvar, du kan svara i vilken kanal du vill."
		}
	}

	# Give the user help
	proc help { nick host hand chan arg } {
		# If the user is OP, give it the op commands too
		set opcommands ", !startmess <intervall> <meddelande>"
		if {[isop $nick $::frogesport::running_chan]} {
			set opcommands ", !answer "
		}
		putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Lista på kommandon:\
			!spell <magi> \[nick\],\
			!stats \[nick\],\
			!time,\
			!recommend,\
			!report <id> <kommentar>,\
			!hof,, !hofarme, !top10, !top10arme, !toptid, !topkpm$opcommands,\
			!compare <nick> \[nick\]...,\
			!comparetot <nick> \[nick\]..."
	}

	# Compare one users stats to another
	proc compare { nick host hand chan arg {total "0"} } {
		# Check if we're comparing total points or season
		set column "season"
		if {$total} {
			set column "total"
		}
		# Set the nicks and count them
		switch [set numnicks [llength [set nicks $arg]]] {
			"0" {
				# If there's no argument, tell the user how to use this command
				putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}!jämför <nick> \[nick\]... - Jämför poäng mellan två eller fler användare. Anges bara ett nick jämförs den personens poäng med din."
				return
			}
			"1" {
				# If there's just one nick, add our own to the list
				lappend nicks $nick
				incr numnicks
			}
		}
		# Create the query list of nicks
		set allnicks "user_nick='[join [::mysql::escape $::frogesport::mysql_conn $nicks] "' OR user_nick='"]'"
		set numrows [::mysql::sel $::frogesport::mysql_conn "SELECT user_nick, user_points_$column FROM users WHERE $allnicks ORDER BY user_points_$column DESC"]
		# If we didn't get the same number of results as we had nicks, one or more nick wasn't found. Find out which one
		if {$numrows != $numnicks} {
			while {[set row [::mysql::fetch $::frogesport::mysql_conn]] != ""} {
				# Find out where the nick was found
				set where [lsearch -nocase $nicks [lindex $row 0]]
				# Remove it. We do this in two steps because we don't want to search the list twise
				set nicks [lreplace $nicks $where $where]
			}
			putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Nick hittades inte: \003${::frogesport::color_nick}[join $nicks "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_nick}"]"
			return
		}
		# Get all user info
		set i 1
		while {[set row [::mysql::fetch $::frogesport::mysql_conn]] != ""} {
			if {![info exists lastpoints]} {
				set after ""
			} else {
				set after ", \003${::frogesport::color_statsnumber}[expr $lastpoints-[lindex $row 1]]\003${::frogesport::color_text} poäng efter"
			}
			set lastpoints [lindex $row 1]
			append output " $i: \003${::frogesport::color_nick}[lindex $row 0]\003${::frogesport::color_text}(\003${::frogesport::color_statsnumber}$lastpoints\003${::frogesport::color_text},${::frogesport::color_background}$after)"
			incr i
		}
		# Output everything!
		putserv "NOTICE $nick :\003${::frogesport::color_text},${::frogesport::color_background}Jämförda användare:$output"
	}
	proc comparetot { nick host hand chan arg } {
		# Compare the totalt points. This procedure would be an almost exact copy of compare, so use that instead
		compare $nick $host $hand $chan $arg "1"
	}
	
	proc msgclan { nick host hand arg } {
		# We need to split the argument to be able to use it as a list.
		set arg [split $arg]
		set arg0 [lindex $arg 0]
		set arg1 [lindex $arg 1]
		set arg1end [lrange $arg 1 end]
		set helpvar "\003${::frogesport::color_text},${::frogesport::color_background}Hjälp: arme skapa <arménamn>|ansök <arménamn>|lämna|roll <nick> <medlem|admin> <ja|nej>|ändra namn <nytt namn>|medlemmar \[arménamn\]"
		# Get info about the current user and clan.
		set curuser [::mysql::sel $::frogesport::mysql_conn "SELECT uid, clan_name, clme_admin, clid, cid FROM users LEFT JOIN clanmembers ON users.uid=clanmembers.clme_uid LEFT JOIN clans ON clanmembers.clme_clid=clans.clid LEFT JOIN classes ON user_class=cid WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $nick]'" -list]
		if {$curuser == ""} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du måste svara rätt på en fråga innan du kan gå med i en armé."
			return
		}
		switch -glob $arg0 {
			"create" - 
			"skapa" {
				if {[llength $arg] < 2} {
					putserv "PRIVMSG $nick :$helpvar"
					return
				}
				# Check the user's level.
				if {[lindex $curuser 0 4] < 6 && [lindex $curuser 0 4] != 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du måste svara rätt på fler frågor innan du får skapa en ny armés."
					return
				}
				# Check if the user already is a member of a clan.
				if {[lindex $curuser 0 1] != ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du får inte skapa en armé om du redan är medlem i en annan, lämna den du är med i först."
					return
				}
				# Check if the requested new clan exists.
				set newclan [::mysql::sel $::frogesport::mysql_conn "SELECT count(*) FROM clans WHERE clan_name='[::mysql::escape $::frogesport::mysql_conn $arg1end]'" -list]
				if {[lindex $newclan 0 0] != 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns redan en armé med namnet \003${::frogesport::color_class}$arg1end\003${::frogesport::color_text}, var vänlig välj ett annat."
					return
				}
				# Create the clan and join the user.
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO clans (clan_name, clan_created, clan_createdby) VALUES ('[::mysql::escape $::frogesport::mysql_conn $arg1end]', UNIX_TIMESTAMP(NOW()), '[lindex $curuser 0 0]')"
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO clanmembers (clme_clid, clme_uid, clme_member, clme_admin, clme_joined) VALUES ('[::mysql::insertid $::frogesport::mysql_conn]', '[lindex $curuser 0 0]', 'yes', 'yes', UNIX_TIMESTAMP(NOW()))"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Armén \003${::frogesport::color_class},${::frogesport::color_background}$arg1end\003${::frogesport::color_text} skapad!"
			}
			"join" -
			"ans?k" {
				if {[llength $arg] < 2} {
					putserv "PRIVMSG $nick :$helpvar"
					return
				}
				# Check the user's level.
				if {[lindex $curuser 0 4] < 2 && [lindex $curuser 0 4] != 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du måste svara rätt på fler frågor innan du får gå med i en armé."
					return
				}
				# Check if the user already is a member of a clan.
				if {[lindex $curuser 0 1] != ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du får inte gå med i fler armeer, lämna den du är med i först."
					return
				}
				# Check if the requested new clan exists.
				set newclan [::mysql::sel $::frogesport::mysql_conn "SELECT count(*), clid FROM clans WHERE clan_name='[::mysql::escape $::frogesport::mysql_conn $arg1end]'" -list]
				if {[lindex $newclan 0 0] == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen armé med namnet \003${::frogesport::color_class}$arg1end\003${::frogesport::color_text},\003${::frogesport::color_background} dubbelkolla stavningen eller skapa en ny med \"arme skapa $arg1end\""
					return
				}
				# Create the clan application!
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO clanmembers (clme_clid, clme_uid, clme_joined) VALUES ('[lindex $newclan 0 1]', '[lindex $curuser 0 0]', UNIX_TIMESTAMP(NOW()))"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Ansökan till \003${::frogesport::color_class}$arg1end\003${::frogesport::color_text} skickad."
			}
			"leave" -
			"l?mna" {
				# Is the user really in a clan?
				if {[lindex $curuser 0 1] == ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte med i någon armé."
					return
				}
				set newclan [::mysql::sel $::frogesport::mysql_conn "SELECT count(*), clan_name FROM clans WHERE clid='[lindex $curuser 0 3]'" -list]
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM clanmembers WHERE clme_uid='[lindex $curuser 0 0]'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Armé \003${::frogesport::color_class}[lindex $newclan 0 1]\003${::frogesport::color_text} lämnad."
				# Are there any users left in the clan? If not, delete the whole clan.
				set memcount [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(*) from clanmembers WHERE clme_clid='[lindex $curuser 0 3]'" -flatlist]
				if {$memcount == 0} {
					::mysql::exec $::frogesport::mysql_conn "DELETE FROM clans WHERE clid='[lindex $curuser 0 3]'"
				} else {
					# If there are members but are no admins left, promote the oldest member.
					set admincount [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(*) from clanmembers WHERE clme_clid='[lindex $curuser 0 3]' AND clme_admin='yes'" -flatlist]
					if {$admincount == 0} {
						::mysql::exec $::frogesport::mysql_conn "UPDATE clanmembers SET clme_admin='yes' WHERE clme_clid='[lindex $curuser 0 3]' ORDER BY FIELD(clme_member, 'yes', 'no'), clme_joined ASC LIMIT 1"
					}
				}
			}
			"role" -
			"roll" {
				set arg2 [lindex $arg 2]
				set arg3 [lindex $arg 3]
				if {$arg3 == ""} {
					putserv "PRIVMSG $nick :$helpvar"
					return
				}
				# Is the user really in a clan?
				if {[lindex $curuser 0 1] == ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte med i någon armé."
					return
				}
				# Admin?
				if {[lindex $curuser 0 2] != "yes"} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte admin i din armé."
					return
				}
				# Get info about the affected user.
				set roleuser [::mysql::sel $::frogesport::mysql_conn "SELECT uid, clan_name, clme_admin, user_nick FROM users LEFT JOIN clanmembers ON users.uid=clanmembers.clme_uid LEFT JOIN clans ON clanmembers.clme_clid=clans.clid WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $arg1]'" -list]
				# Is there any matching user?
				if {[lindex $roleuser 0 1] == ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}$arg1\003${::frogesport::color_text} är inte med i någon armé."
					return
				}
				# Are the user and user in the same clan?
				if {[lindex $roleuser 0 1] != [lindex $curuser 0 1]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du och \003${::frogesport::color_nick}[lindex $roleuser 0 3]\003${::frogesport::color_text} är inte med i samma armé."
					return
				}
				#clan role pelle admin yes/ja
				switch -glob $arg2 {
					"admin" {
						if {[string match -nocase $arg3 "yes"] || [string match -nocase $arg3 "ja"]} {
							::mysql::exec $::frogesport::mysql_conn "UPDATE clanmembers SET clme_admin='yes', clme_member='yes' WHERE clme_uid='[lindex $roleuser 0 0]'"
							putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $roleuser 0 3]\003${::frogesport::color_text} är nu admin."
						} elseif {[string match -nocase $arg3 "no"] || [string match -nocase $arg3 "nej"]} {
							::mysql::exec $::frogesport::mysql_conn "UPDATE clanmembers SET clme_admin='no' WHERE clme_uid='[lindex $roleuser 0 0]'"
							putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $roleuser 0 3]\003${::frogesport::color_text} är nu inte admin längre."
						} else {
							putserv "PRIVMSG $nick :$helpvar"
						}
					}
					"medlem" -
					"member" {
						if {[string match -nocase $arg3 "yes"] || [string match -nocase $arg3 "ja"]} {
							::mysql::exec $::frogesport::mysql_conn "UPDATE clanmembers SET clme_member='yes' WHERE clme_uid='[lindex $roleuser 0 0]'"
							putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $roleuser 0 3]\003${::frogesport::color_text} är nu medlem."
						} elseif {[string match -nocase $arg3 "no"] || [string match -nocase $arg3 "nej"]} {
							::mysql::exec $::frogesport::mysql_conn "DELETE from clanmembers WHERE clme_uid='[lindex $roleuser 0 0]'"
							putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $roleuser 0 3]\003${::frogesport::color_text} är nu inte medlem längre."
						} else {
							putserv "PRIVMSG $nick :$helpvar"
						}
					}
					default {
						putserv "PRIVMSG $nick :$helpvar"
					}
				}
			}
			"modify" -
			"?ndra" {
				# Change name
				set arg2end [lrange $arg 2 end]
				# Is the user really in a clan?
				if {[lindex $curuser 0 1] == ""} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte med i någon armé."
					return
				}
				# Admin?
				if {[lindex $curuser 0 2] != "yes"} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte admin i din armé."
					return
				}
				switch -glob $arg1 {
					"name" -
					"namn" {
						if {$arg2end == "" } {
							putserv "PRIVMSG $nick :$helpvar"
							return
						}
						set dupcheck [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(*) from clans WHERE clan_name='[::mysql::escape $::frogesport::mysql_conn $arg2end]'" -flatlist]
						if {$dupcheck != 0} {
							putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Arménamnet är redan upptaget."
							return
						}
						::mysql::exec $::frogesport::mysql_conn "UPDATE clans SET clan_name='[::mysql::escape $::frogesport::mysql_conn $arg2end]' WHERE clid=(SELECT clme_clid FROM clanmembers WHERE clme_uid=[lindex $curuser 0 0])"
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Arménamn ändrat."
					}
				}
			}
			"medlemmar" -
			"members" -
			"status" {
				set arg1end [lrange $arg 1 end]
				# Do the user want to see a specific clan?
				if {$arg1end == ""} {
					putlog $arg1end
					# Nope. Is the user in a clan?
					if {[lindex $curuser 0 3] == ""} {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Du är inte med i någon armé."
						return
					}
					set currentclan [lindex $curuser 0 3]
				} else {
					set statusclan [::mysql::sel $::frogesport::mysql_conn "SELECT clid FROM clanmembers LEFT JOIN clans ON clanmembers.clme_clid=clans.clid WHERE clan_name='[::mysql::escape $::frogesport::mysql_conn $arg1end]'" -flatlist]
					if {$statusclan == ""} {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Armén $arg2end finns inte."
						return
					}
					set currentclan [lindex $statusclan 0]
				}
				set query "SELECT
					clan_name, user_nick, clme_admin, clme_member
				FROM
					clanmembers
				LEFT JOIN
					users ON clme_uid=uid
				LEFT JOIN
					clans ON clme_clid=clid
				WHERE
					clid='$currentclan'"
				set clanmembers [::mysql::sel $::frogesport::mysql_conn $query -list]
				set output "\003${::frogesport::color_text},${::frogesport::color_background}Medlemmar i armén [lindex $clanmembers 0 0]: "
				foreach clanmember $clanmembers {
					set output "$output\003${::frogesport::color_nick},${::frogesport::color_background}[lindex $clanmember 1]\003${::frogesport::color_text} "
					if {[lindex $clanmember 2] == "yes"} {
						set output "$output\003${::frogesport::color_class}\[Admin\]\003${::frogesport::color_text},${::frogesport::color_background}"
					}
					if {[lindex $clanmember 3] == "no"} {
						set output "$output\003${::frogesport::color_class}\[Ansökt\]\003${::frogesport::color_text},${::frogesport::color_background}"
					}
					set output "$output, "
				}
				putserv [string trimright "PRIVMSG $nick :$output" ", "]
			}
			"list" -
			"lista" {
				
				set query "SELECT
					clan_name, count(*)
				FROM
					clanmembers
				LEFT JOIN
					clans ON clme_clid=clid
				WHERE
					clme_member='yes'
				GROUP BY
					clan_name"
				set clans [::mysql::sel $::frogesport::mysql_conn $query -list]
				set output "\003${::frogesport::color_text},${::frogesport::color_background}Arméer: "
				foreach clan $clans {
					set output "$output\003${::frogesport::color_class},${::frogesport::color_background}[lindex $clan 0]\003${::frogesport::color_text},${::frogesport::color_background} (\003${::frogesport::color_statsnumber}[lindex $clan 1]\003${::frogesport::color_text} medlemmar), "
				}
				putserv [string trimright "PRIVMSG $nick :$output" ", "]
			}
			default {
				putserv "PRIVMSG $nick :$helpvar"
			}
		}
	}

	# Admins shouldn't have to use !stats in public to check a user
	proc msgchecku { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		stats $nick $host $hand "" $arg
	}

	# These procesures are very similar, so we use a single one for all of them
	proc punish { nick host chan hand arg } {
		rewpun "punish" $nick [string trim $arg]
	}
	proc reward { nick host chan hand arg } {
		rewpun "reward" $nick [string trim $arg]
	}
	proc rewpun { action nick arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		set points $::frogesport::rewpun_points
		if {[regexp "^\[0-9\]+\$" [string trim [lindex $arg 1]]]} {
			set points [string trim [lindex $arg 1]]
		}
		switch $action {
			"reward" {
				set operator "+"
				set message "\003${::frogesport::color_nick},${::frogesport::color_background}$nick\003${::frogesport::color_text} belönade \003${::frogesport::color_nick}[lindex $arg 0]\003${::frogesport::color_text} med \003${::frogesport::color_statsnumber}$points\003${::frogesport::color_text} poäng!"
			}
			"punish" {
				set operator "-"
				set message "\003${::frogesport::color_nick},${::frogesport::color_background}$nick\003${::frogesport::color_text} bestraffade \003${::frogesport::color_nick}[lindex $arg 0]\003${::frogesport::color_text} med \003${::frogesport::color_statsnumber}$points\003${::frogesport::color_text} poäng!"
			}
		}
		set numrows [::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=user_points_season$operator$points WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn [lindex $arg 0]]' LIMIT 1"]
		if {$numrows > 0} {
			putserv "PRIVMSG $::frogesport::running_chan :$message"
		}
	}

	# These procesures are very similar, so we use a single one for all of them here too
	proc msgcheckq { nick host hand arg } {
		checkdelq $nick $arg "check"
	}
	proc msgdelq { nick host hand arg } {
		checkdelq $nick $arg "del"
	}
	# checkq should be availible in public too, as !check
	proc check { nick host hand chan arg } {
		checkdelq $nick $arg "check"
	}

	# This procedure gives an admin a question and its answers from and ID, temporary or real
	proc checkdelq { nick arg {action "check"} } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Split the argument
		set id [lindex $arg 0]
		set perm [lindex $arg 1]
		# If the user wants help, give it that!
		if {![regexp "^\[0-9\]+\$" $id]} {
			switch $action {
				"check" {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}checkq <id> \[perm\] - Visa en fråga och dess svar. Om ordet \"perm\" finns med används frågans permanenta ID istället för det temporära."
				}
				"del" {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}delq <id> \[perm\] - Tar bort en fråga. Om ordet \"perm\" finns med används frågans permanenta ID istället för det temporära."
				}
			}
			return
		}
		set column "ques_tempid"
		# Check if the keyword is perm
		if {$perm == "perm"} {
			set column "qid"
		} else {
			set id $id.$::frogesport::bot_id
		}
		# Get the question and answers in one query by joining the tables
		set numrows [::mysql::sel $::frogesport::mysql_conn "SELECT questions.qid, questions.ques_category, questions.ques_question, questions.ques_tempid, questions.ques_source, questions.ques_addedby, answers.answ_answer, answers.answ_prefer FROM questions LEFT JOIN answers ON questions.qid=answers.answ_question WHERE questions.$column='[::mysql::escape $::frogesport::mysql_conn $id]'"]
		set row [::mysql::fetch $::frogesport::mysql_conn]
		# If we didn't get any rows, tell the user and quit
		if {$numrows == 0} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Ingen fråga med det IDt."
			return
		}
		# Set all variables that are not answers
		set qid [lindex $row 0]
		set category [lindex $row 1]
		set question [lindex $row 2]
		set tempid [lindex $row 3]
		set source [lindex $row 4]
		set addedby [lindex $row 5]
		set prefered ""
		if {[lindex $row 7] == "1"} {
			set prefered "\u00A7"
		}
		set answers [list $prefered[lindex $row 6]]
		# Get the rest of the answers
		while {[set row [::mysql::fetch $::frogesport::mysql_conn]] != ""} {
			# Check if the answer is preferred.
			set prefered ""
			if {[lindex $row 7] == "1"} {
				set prefered "\u00A7"
			}
			lappend answers $prefered[lindex $row 6]
		}
		# Check if we're deleting the question
		set deletemess ""
		if {$action == "del"} {
			::mysql::exec $::frogesport::mysql_conn "DELETE FROM questions WHERE qid=$qid"
			::mysql::exec $::frogesport::mysql_conn "DELETE FROM answers WHERE answ_question=$qid"
			::mysql::exec $::frogesport::mysql_conn "DELETE FROM reports WHERE repo_qid=$qid"
			set deletemess "Du tog bort den här frågan:"
		}
		# Output the question and the answers
		putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}$deletemess\
			Permanent ID: \003${::frogesport::color_statsnumber}$qid\003${::frogesport::color_text}\
			Skapad av: \003${::frogesport::color_statsnumber}$addedby\003${::frogesport::color_text}\
			Temporärt ID: \003${::frogesport::color_statsnumber}$tempid\003${::frogesport::color_text}\
			Kategori: \003${::frogesport::color_statsnumber}$category\003${::frogesport::color_text}\
			Fråga: \003${::frogesport::color_statsnumber}$question\003${::frogesport::color_text}\
			Svar: \003${::frogesport::color_statsnumber}[join $answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_statsnumber}"]\003${::frogesport::color_text}\
			Källa: \003${::frogesport::color_statsnumber}$source\003${::frogesport::color_text}"
	}

	# Add a question
	proc msgaddq { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Trim any leading or trailing pipes, spaces and tabs
		set arg [string trim $arg "| 	"]
		# Split the argument
		set source [lindex [split $arg "|"] 0]
		set category [lindex [split $arg "|"] 1]
		set question [lindex [split $arg "|"] 2]
		set answers [lrange [split $arg "|"] 3 end]
		# Check if the user wants help, didn't write multiple pipes after eachother and that there are enought parameters
		if {$arg == "help" || [string match -nocase $arg "hj?lp"] || $arg == "" || [regexp "\\|\\|" $arg] || ![llength $answers]} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}addq <källa>|<kategori>|<Fråga>|<svar>\[|svar\]... - Lägg till en fråga. Kategori, fråga och svar är avskilda med | (pipe). Det finns ingen gräns på antalet svar. Skriv \u00A7 i början av ett svar för att använda det för att skapa ledtråden."
			return
		}
		# Add the question
		::mysql::exec $::frogesport::mysql_conn "INSERT INTO questions (ques_category, ques_question, ques_source, ques_addedby) VALUES('[::mysql::escape $::frogesport::mysql_conn $category]', '[::mysql::escape $::frogesport::mysql_conn $question]', '[::mysql::escape $::frogesport::mysql_conn $source]', '[::mysql::escape $::frogesport::mysql_conn $nick]')"
		# Get the ID of the question we just entered
		set qid [::mysql::insertid $::frogesport::mysql_conn]
		# Generate and submit the SQL query for the answers
		foreach answer $answers {
			# Check if the answer is prefered.
			set prefer "0"
			if {[scan [string index $answer 0] %c] == [scan "\u00A7" %c]} {
				set answer [string range $answer 1 end]
				set prefer "1"
			}
			lappend sql_answers "('$qid', '[::mysql::escape $::frogesport::mysql_conn $answer]', '$prefer')" 
		}
		::mysql::exec $::frogesport::mysql_conn "INSERT INTO answers (answ_question, answ_answer, answ_prefer) VALUES[join $sql_answers ", "]"
		putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Fråga med ID \003${::frogesport::color_statsnumber}$qid\003${::frogesport::color_text} tillagd!"
	}

	# Modify a question
	proc msgmodq { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Trim any leading or trailing pipes, spaces and tabs
		set arg [string trim $arg "| 	"]
		# Split the argument, differently depending on if the perm keyword is present
		set id [lindex [split $arg] 0]
		set perm [lindex [split $arg] 1]
		# Check if the user wants help
		if {![regexp "^\[0-9\]+\$" $id]} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modq <id> \[perm\] <kategori|fråga|svar> <nytt värde> - Modifiera en del av en fråga"
			return
		}
		if {$perm == "perm"} {
			set column "qid"
			set action [lindex [split $arg] 2]
			set value [join [lrange [split $arg] 3 end]]
		} else {
			set column "ques_tempid"
			set action [lindex [split $arg] 1]
			set value [join [lrange [split $arg] 2 end]]
			set id $id.$::frogesport::bot_id
		}
		# Check if there is any question
		set row [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT qid, ques_tempid FROM questions WHERE $column='[::mysql::escape $::frogesport::mysql_conn $id]'" -list] 0]
		# If we didn't get any rows, tell the user and quit
		if {$row == ""} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen fråga med det IDt."
			return
		}
		# Set some variables to make it easier to read
		set qid [lindex $row 0]
		set tempid [lindex $row 1]
		# Do what the user wanted us to do
		switch -glob $action {
			"kategori" -
			"category" {
				::mysql::exec $::frogesport::mysql_conn "UPDATE questions SET ques_category='[::mysql::escape $::frogesport::mysql_conn $value]' WHERE qid='$qid'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Kategorin för frågan med permanent ID \003${::frogesport::color_statsnumber}$qid\003${::frogesport::color_text} och temporärt ID \003${::frogesport::color_statsnumber}$tempid\003${::frogesport::color_text} satt till \003${::frogesport::color_statsnumber}$value"
			}
			"fr?ga" -
			"question" {
				::mysql::exec $::frogesport::mysql_conn "UPDATE questions SET ques_question='[::mysql::escape $::frogesport::mysql_conn $value]' WHERE qid='$qid'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Frågan med permanent ID \003${::frogesport::color_statsnumber}$qid\003${::frogesport::color_text} och temporärt ID \003${::frogesport::color_statsnumber}$tempid\003${::frogesport::color_text} satt till \003${::frogesport::color_statsnumber}$value"
			}
			"svar" -
			"answer" {
				# Remove heading and trailing pipes
				set value [string trim $value "| 	"]
				# Check if the answers are correctly put
				if {[regexp "\\|\\|" $arg]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modq <id> \[perm\] answer <svar>\[|svar\]... - Sätt svaren för en fråga. Svar är avskilda med | (pipe)."
					return
				}
				# Split the answers at the pipes
				set answers [split $value "|"]
				# Create the SQL query
				foreach answer $answers {
					# Check if the answer is prefered.
					set prefer "0"
					if {[scan [string index $answer 0] %c] == [scan "\u00A7" %c]} {
						set answer [string range $answer 1 end]
						set prefer "1"
					}
					lappend sql_answers "('$qid', '[::mysql::escape $::frogesport::mysql_conn $answer]', '$prefer')"
				}
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM answers WHERE answ_question='$qid'"
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO answers (answ_question, answ_answer, answ_prefer) VALUES[join $sql_answers ", "]"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Svaren till frågan med permanent ID \003${::frogesport::color_statsnumber}$qid\003${::frogesport::color_text} och temporärt ID \003${::frogesport::color_statsnumber}$tempid\003${::frogesport::color_text} satt till \003${::frogesport::color_statsnumber}[join $answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_statsnumber}"]"
			}
			default {
				# If the user didn't supply a valid action, tell it how the command should be run
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modq <id> \[perm\] <kategori|fråga|svar> <nytt värde> - Modifiera en fråga. Du måste ange ID, om ordet \"perm\" finns med används frågans permanenta ID istället för det temporära, vad som ska ändras och vad det ska ersättas med. Flera svar är skilda med | (pipe)."
				return
			}
		}
	}

	# Modify a user
	proc msgmodu { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Split the argument
		set action [lindex [split $arg] 0]
		set user [lindex [split $arg] 1]
		set value [lindex [split $arg] 2]
		# Determine what to change
		switch -glob -nocase $action {
			"hj?lp" -
			"help" {
				# Output a lot of help
				switch -glob -nocase $user {
					"nick" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu nick <gammalt nick> <nytt nick> - Byter nick på en användare."
					}
					"s?song" -
					"season" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu season <nick> <poäng> - Sätter en användares säsongspoäng."
					}
					"totalt" -
					"total" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu total <nick> <poäng> - Sätter en användares totala poäng."
					}
					"time" -
					"tid" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu time <nick> <tid> - Sätter en användares bästa tid."
					}
					"inarow" -
					"streak" -
					"irad" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu strak <nick> <antal> - Sätter en användares bästa streak."
					}
					"mana" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu mana <nick> <mana> - Sätter en användares mana."
					}
					"class" -
					"klass" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu class <nick> <klass> - Sätter en användares klass. Kan anges som siffra eller namn."
					}
					"last" -
					"senast" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu last <nick> <unix-tid> - Sätter när en användare senast svarade rätt på en fråga. Anges i UNIX-tid."
					}
					"customklass" -
					"customclass" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu customclass <nick> <customklass> - Sätter en användares egna klass. Detta är bara ett namn och påverkar ingen mana eller spell."
					}
					"transfer" {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu transfer <old nick> <new nick> - Flyttar ett nicks poäng, mana och streak till ett annat nick. Det gamla kommer att tas bort helt."
					}
					default {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu help <nick|season|total|time|streak|mana|class|last|customclass> - Visar hjälp om ett alternativ"
					}
				}
				return
			}
			"nick" {
				# Check if the old and new nick exists
				set numvalue [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(uid) FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $value]'" -list] 0]
				set numusers [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(uid) FROM users WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]'" -list] 0]
				if {$numusers == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen användare med det nicket!"
					return
				}
				if {$numvalue != 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns redan en användare med det nicket!"
					return
				}
				set column "user_nick"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}${user}\003${::frogesport::color_text}s nick ändrat till \003${::frogesport::color_nick}$value"
			}
			"s?song" -
			"season" {
				# Check if the points are numeric only
				if {![string is integer -strict $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Poängen måste vara ett heltal."
					return
				}
				set column "user_points_season"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s säsongspoäng ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"total" -
			"totalt" {
				# Check if the points are numeric only
				if {![string is integer -strict $value] || $value < "0"} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Poängen måste vara ett positivt heltal."
					return
				}
				# We have to check if the class is supposed to be updated too, which is done easiest with MySQL.
				set newclass [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT * FROM classes WHERE clas_points<='$value' ORDER BY clas_points DESC LIMIT 1" -list] 0]
				::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_class='$newclass' WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]' AND user_class!=0"
				set column "user_points_total"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s totala poäng ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"time" -
			"tid" {
				# Check that the time is a double (regex /\d+\.\d+/) or an integer
				set value [string map {"," "."} $value]
				if {![string is double -strict $value] && ![string is integer -strict $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Tiden måste vara ett decimal- eller heltal."
					return
				}
				set column "user_time"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s snabbaste tid ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"inarow" -
			"streak" -
			"irad" {
				# Check that the streak is an integer
				if {![string is integer -strict $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Streaken måste vara ett heltal."
					return
				}
				set column "user_inarow"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s streak ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"mana" {
				# Check that the mana is an integer
				if {![string is integer -strict $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Manan måste vara ett heltal."
					return
				}
				set column "user_mana"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s mana ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"class" -
			"klass" {
				# Check if the class is in the class list
				if {[lsearch -index 0 $::frogesport::classes $value] == "-1"} {
					# If not, get the class number from the name, which can contain spaces
					set value [join [lrange [split $arg] 2 end]]
					if {[set value [lsearch -nocase -index 2 $::frogesport::classes $value]] == "-1"} {
						putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Ogiltig klass."
						return
					}
				}
				set column "user_class"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s klass ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"last" -
			"senast" {
				# Check that the time is an integer
				if {![string is integer -strict $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Tiden måste vara ett heltal."
					return
				}
				set column "user_lastactive"
				set newvalue $value
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s senaste aktiva tid ändrad till \003${::frogesport::color_statsnumber}$value"
			}
			"customklass" -
			"customclass" {
				set column "user_customclass"
				set newvalue [join [lrange [split $arg] 2 end]]
				if {$newvalue == ""} {
					set newcusclass "Default"
				} else {
					set newcusclass $newvalue
				}
				set message "\003${::frogesport::color_text},${::frogesport::color_background}Användaren \003${::frogesport::color_nick}$user\003${::frogesport::color_text}s customklass ändrad till \003${::frogesport::color_statsnumber}$newcusclass"
			}
			"transfer" {
				# Get info about the two users
				set user1 [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(`uid`), `user_points_season`, `user_points_total`, `user_time`, `user_inarow`, `user_mana`, `user_class`, `user_lastactive`, `user_customclass` FROM users WHERE `user_nick`='[::mysql::escape $::frogesport::mysql_conn $user]'" -list] 0]
				set user2 [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(`uid`), `user_points_season`, `user_points_total`, `user_time`, `user_inarow`, `user_mana`, `user_class`, `user_lastactive`, `user_customclass` FROM users WHERE `user_nick`='[::mysql::escape $::frogesport::mysql_conn $value]'" -list] 0]
				# Check if they exist
				if {[lindex $user1 0] == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen användare med nicket $user!"
					return
				}
				if {[lindex $user2 0] == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen användare med nicket $value!"
					return
				}
				set newtotal [expr [lindex $user1 2]+[lindex $user2 2]]
				# If one of the nicks' class is 0, keep it
				if {[lindex $user1 6] == "0" || [lindex $user2 6] == "0"} {
					::mysql::sel $::frogesport::mysql_conn "SELECT `cid`, `clas_maxmana` FROM `classes` WHERE `cid`='0'"
					set newclass [::mysql::fetch $::frogesport::mysql_conn]
				} else {
					::mysql::sel $::frogesport::mysql_conn "SELECT `cid`, `clas_maxmana` FROM `classes` WHERE `clas_points`<='$newtotal' ORDER BY `clas_points` DESC LIMIT 1"
					set newclass [::mysql::fetch $::frogesport::mysql_conn]
				}
				set newmana [expr [lindex $user1 5]+[lindex $user2 5]]
				set newvalues "`user_points_season`='[lindex $user1 1]'+'[lindex $user2 1]', `user_points_total`='$newtotal', `user_class`='[lindex $newclass 0]'"
				if {[lindex $user1 3] < [lindex $user2 3]} {
					append newvalues ", `user_time`='[lindex $user1 3]'"
				}
				if {[lindex $user1 4] > [lindex $user2 4]} {
					append newvalues ", `user_inarow`='[lindex $user1 4]'"
				}
				if {$newmana > [lindex $newclass 1]} {
					append newvalues ", `user_mana`='[lindex $newclass 1]'"
				} else {
					append newvalues ", `user_mana`='$newmana'"
				}
				if {[lindex $user1 7] > [lindex $user2 7]} {
					append newvalues ", `user_lastactive`='[lindex $user1 7]'"
				}
				if {[lindex $user2 8] == ""} {
					append newvalues ", `user_customclass`='[lindex $user1 8]'"
				}
				::mysql::exec $::frogesport::mysql_conn "UPDATE `users` SET $newvalues WHERE `user_nick`='[::mysql::escape $::frogesport::mysql_conn $value]'"
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM `users` WHERE `user_nick`='[::mysql::escape $::frogesport::mysql_conn $user]'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_nick},${::frogesport::color_background}$user\003${::frogesport::color_text}'s poäng, snabbaste tid, streak, mana, senast aktiva tid och ev. customclass flyttad till \003${::frogesport::color_nick}$value\003${::frogesport::color_text}! Klassen är även uppdaterad."
				return
			}
			default {
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}modu <nick|season|total|time|inarow|mana|class|last|customclass|transfer|help> <nick|subcommand> \[new value/nick\] - Ändra en användare. Help visar mer detaljerad hjälp om ett alternativ."
				return
			}
		}
		# Change stuff
		set numupdated [::mysql::exec $::frogesport::mysql_conn "UPDATE users SET $column='[::mysql::escape $::frogesport::mysql_conn $newvalue]' WHERE user_nick='[::mysql::escape $::frogesport::mysql_conn $user]'"]
		if {$numupdated} {
			putserv "PRIVMSG $nick :$message"
		} else {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Ingen rad ändrad. Det finns ingen användare med det nicket, eller så har användaren redan det angivna värdet."
		}
	}

	proc msghelp { nick host hand arg } {
		putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Hjälp för kommandon skrivna här i PM: recommend <källa på frågan>|<kategori>|<fråga>|<svar>\[|<svar>\]..., arme hjälp"
		# Admins should have more help
		if {[checkauth $nick]} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Hjälp för admins, skrivna i kanalen: !startquiz, !stopquiz, !answer"
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Hjälp för admins, skrivna här i PM:\
				addq <källa>|<kategori>|<fråga>|<svar>\[|svar],\
				checkq <id> \[perm\],\
				delq <id> \[perm\],\
				modq <id> \[perm\]  <kategori|fråga|svar> <nytt värde>,\
				modu <nick|säsong|total|tid|irad|mana|klass|senast|hjälp> <nick|alternativ> \[nytt värde\],\
				newseason help,\
				rapporter <visa|radera> \[id\],\
				updateclasses"
		}
	}

	proc msgreports { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# Get what the user wants to do
		set action [lindex [split $arg] 0]
		set value [lindex [split $arg] 1]
		# Check if the user wants help, we put it here so that we won't have to put the MySQL code in each switch block
		if {$action == "help" || [string match -nocase $arg "hj?lp"] || $arg == ""} {
			putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}rapporter <visa|radera> \[rapportens id\] - Visar och tar bort rapporter."
			return
		}
		switch $action {
			"visa" -
			"show" {
				set numreports [lindex [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(rid) FROM reports" -list] 0]
				# Select rows that has not been viewed in a long time (or at all.)
				set allrows [::mysql::sel $::frogesport::mysql_conn "SELECT reports.rid, reports.repo_qid, reports.repo_comment, reports.repo_user, questions.ques_category,\
					questions.ques_question FROM reports LEFT JOIN questions ON reports.repo_qid=questions.qid ORDER BY reports.repo_lastshow ASC, reports.repo_qid DESC LIMIT [::mysql::escape $::frogesport::mysql_conn $::frogesport::reports_show]" -list]
				if {[llength $allrows] == 0} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Inga rapporter!"
					return
				}
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}De $::frogesport::reports_show översta rapporterna av totalt $numreports:"
				foreach row $allrows {
					# Remember the IDs of all show reports
					lappend allids [lindex $row 0]
					# Get the answers
					set answerresp [::mysql::sel $::frogesport::mysql_conn "SELECT answ_answer, answ_prefer FROM answers WHERE answ_question='[::mysql::escape $::frogesport::mysql_conn [lindex $row 1]]'" -list]
					# Put the answers in a list
					foreach answer $answerresp {
						# Check if the answer is preferred
						set prefered ""
						if {[lindex $answer 1] == "1"} {
							set prefered "\u00A7"
						}
						lappend answers $prefered[lindex $answer 0]
					}
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Rapportens ID: \003${::frogesport::color_statsnumber}[lindex $row 0]\003${::frogesport::color_text}\
						nick: \003${::frogesport::color_nick}[lindex $row 3]\003${::frogesport::color_text}\
						Frågans permanenta ID: \003${::frogesport::color_statsnumber}[lindex $row 1]\003${::frogesport::color_text}\
						Kommentar: \003${::frogesport::color_answer}[lindex $row 2]\003${::frogesport::color_text}\
						Kategori: \003${::frogesport::color_answer}[lindex $row 4]\003${::frogesport::color_text}\
						Fråga: \003${::frogesport::color_answer}[lindex $row 5]\003${::frogesport::color_text}\
						Svar: \003${::frogesport::color_answer}[join $answers "\003${::frogesport::color_text},${::frogesport::color_background}, \003${::frogesport::color_answer}"]\003${::frogesport::color_text}."
				}
				::mysql::exec $::frogesport::mysql_conn "UPDATE reports SET repo_lastshow=UNIX_TIMESTAMP(NOW()) WHERE rid IN ([join $allids ", "])"
			}
			"radera" -
			"del" -
			"delete" {
				# Check if the supplied id is numeric
				if {![regexp "^\[0-9\]+\$" $value]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_statsnumber},${::frogesport::color_background}$value\003${::frogesport::color_text} är inte ett giltigt rapportID."
					return
				}
				set count [::mysql::sel $::frogesport::mysql_conn "SELECT COUNT(rid) FROM reports WHERE rid='[::mysql::escape $::frogesport::mysql_conn $value]'" -list]
				if {![lindex $count 0]} {
					putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det finns ingen rapport med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text}."
					return
				}
				::mysql::exec $::frogesport::mysql_conn "DELETE FROM reports WHERE rid='[::mysql::escape $::frogesport::mysql_conn $value]'"
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Rapporten med ID \003${::frogesport::color_statsnumber}$value\003${::frogesport::color_text} borttagen!"
			}
			default {
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Visar och tar bort rapporter. Användning: rapporter visa, rapporter radera <id>"
				return
			}
		}
	}

	proc msgnewseason { nick host hand arg } {
		# Only admins are allowed to use this procedure
		if {![checkauth $nick]} {
			return
		}
		# If there is no argument it matches the empty ::frogesport::season_code, we DEFINITELY don't want that
		if {$arg == ""} {
			set arg "help"
		}
		switch -glob -- $arg $::frogesport::season_code {
				# The user privided the correct password, clear the after timeout and tell the user
				after cancel $::frogesport::season_timeout
				putnow "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Rätt lösenord, kopiering och rensning påbörjad..."
				# Copy the user table and clear the old one's season points
				# If there is an old table lying around, delete it and create a new one
				::mysql::exec $::frogesport::mysql_conn "DROP TABLE IF EXISTS users_last_season"
				::mysql::exec $::frogesport::mysql_conn "CREATE TABLE users_last_season LIKE users"
				# Copy the users
				::mysql::exec $::frogesport::mysql_conn "INSERT INTO users_last_season SELECT * FROM users"
				# Clear the season stats in the old one
				::mysql::exec $::frogesport::mysql_conn "UPDATE users SET user_points_season=0"
				putnow "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Klar! Den gamla tabellen är nu sparad i users_last_season och en ny säsong är påbörjad."
			}\
			"I am sure" -\
			"Jag ?r s?ker" {
				# A new password is generated, if any pending ones are still here, remove them
				catch { after cancel $::frogesport::season_timeout }
				variable season_code [randomstring "16"]
				variable season_nick $nick
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Okej, du vill starta en ny säsong. Men bara för att vara helt säkra, du har nu 1 minut på dig att skriva det här: \"\003${::frogesport::color_answer}newseason $::frogesport::season_code\003${::frogesport::color_text}\"."
				variable season_timeout [after "60000" ::frogesport::season_timeout]
			}\
			default {
				putserv "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Det här kommandot kopierar användartabellen till users_last_season och rensar user_season_points i den gamla. Är du helt säker på att du vill göra detta så skriv \"\003${::frogesport::color_answer}newseason Jag är säker\003${::frogesport::color_text}\"."
			}
	}

	# The time for entering the new season code is up
	proc season_timeout { } {
		putserv "PRIVMSG $::frogesport::season_nick :\003${::frogesport::color_text},${::frogesport::color_background}Tiden har gått ut, det gamla lösenordet gäller inte längre."
		variable season_code ""
	}

	# Procedure to generate a random string
	proc randomstring {length {chars "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"}} {
		set range [expr {[string length $chars]-1}]
		set output ""
		for {set i 0} {$i < $length} {incr i} {
			set pos [expr {int(rand()*$range)}]
			append output [string range $chars $pos $pos]
		}
		return $output
	}

	proc version { nick host hand chan arg } {
		putnow "PRIVMSG $nick :\003${::frogesport::color_text},${::frogesport::color_background}Frogesport version $::frogesport::version"
	}
}

putlog "Frogesport version $::frogesport::version Loaded"
