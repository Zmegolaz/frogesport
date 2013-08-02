###########################################################################
### Frogesport                                                          ###
###########################################################################
###
#
#    Copyright 2011-2013 Zmegolaz <zmegolaz@kaizoku.se>
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
###

############################################################
###                    Configuration                     ###
############################################################

# Edit these to match your MySQL settings
variable mysql_user "frogesport"
variable mysql_pass "secret"
variable mysql_host "localhost"
variable mysql_dbname "frogesport"

# Channel the bot is used in, this has to be correct to be able to start the quiz
variable running_chan "#channel"

# Set authentication method
variable auth_method "2"
# 1: Check if the user is op in the running channel and if the user is class 0 in the database
# 2: Check if the user is op in the running channel and is in the configured list of admins
# 3: Check if the user is op in the admin channel

# Bot admins, separated by space. Only needed if auth_method is set to 2
variable admins "your-nick"
# Channel with the bot admins. Only needed if auth_method is set to 3
variable admin_chan "#channel-admin"

# Time between questions, in seconds
variable s_question_time "10"
# Time until clue is given, in seconds
variable s_clue_time "15"
# Time users have to answer the question, in seconds
variable s_time_answer "30"
# The bot may tell people how long time behind the winner they were, for how long should it collect nicks?
# Enter in seconds, and has to be lower than s_question_time. Set to 0 to disable this feature.
variable s_close_behind "3"

# How many percent of each word in the answer the clue should display, number of letters are rounded up
variable clue_percent "30"

# Set this to 1 if the bot should give the answers if no user answered correctly
variable give_answer "0"

# At which level should users be allowed to cast spells?
variable spell_level "5"
# Cost of the spells
variable cost_steal "50"
variable cost_give "50"
variable cost_answer "50"
variable cost_setvoice "10"
variable cost_prevanswer "20"
# How many points should be stolen or given?
variable steal_points "5"
variable give_points "5"
# How many points should !punish and !reward take/give?
variable reward_points "5"
variable punish_points "5"

# How many reports nad recommended questions should be shown in PM?
# Be careful, to high and the bot'll be too busy pasting reports and won't answer other commands
# A web interface to check all is preferred
variable reports_show "7"
variable recommend_show "7"

# How many seconds has to pass between each ping command?
variable s_pinginterval "10"

# The bot can send periodic messages to the channel, for example to tell people why it is down. What should that message be?
variable periodic_message "Frogesport is down because of database maintenance."
# How often? In minutes.
variable s_periodic_message "1"

# Text color:
variable color_text "00"
# Text background color
variable color_background "01"
# Color of users nicks
variable color_nick "09"
# Color of classes
variable color_class "08"
# Color of answers
variable color_answer "04"
# Color of numbers in stats
variable color_statsnumber "04"

# Colors:
#00 white
#01 black
#02 blue (navy)
#03 green
#04 red
#05 brown (maroon)
#06 purple
#07 orange (olive)
#08 yellow
#09 light green (lime)
#10 teal (a green/blue cyan)
#11 light cyan (cyan) (aqua)
#12 light blue (royal)
#13 pink (light purple) (fuchsia)
#14 grey
#15 light grey (silver)

