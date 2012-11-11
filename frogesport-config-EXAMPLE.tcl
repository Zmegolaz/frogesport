###########################################################################################################
### Frogesport                                                                                          ###
###########################################################################################################
###
#
#    Copyright 2011-2012 Zmegolaz <zmegolaz@kaizoku.se>
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
set ::trivia_mysql_user "frogesport"
set ::trivia_mysql_pass "secret"
set ::trivia_mysql_host "localhost"
set ::trivia_mysql_dbname "frogesport"

# Channel the bot is used in, this has to be correct to be able to start the quiz
set ::running_chan "#channel"

# Set authentication method
set ::auth_method "2"
# 1: Check if the user is op in the running channel and if the user is class 0 in the database
# 2: Check if the user is op in the running channel and is in the configured list of admins
# 3: Check if the user is op in the admin channel

# Bot admins, separated by space. Only needed if ::auth_method is set to 2
set ::admins "yournick"
# Channel with the bot admins. Only needed if ::auth_method is set to 3
set ::admin_chan "#channel-admin"

# Time between questions, in seconds
set ::s_question_time "10"
# Time until clue is given, in seconds
set ::s_clue_time "15"
# Time users have to answer the question, in seconds
set ::s_time_answer "30"

# How many percent of each word in the answer the clue should display, number of letters are rounded up
set ::clue_percent "30"

# Set this to 1 if the bot should give the answers if no user answered correctly
set ::give_answer "1"

# At which level should users be allowed to cast spells?
set ::spell_level "5"
# Cost of the spells
set ::cost_steal "50"
set ::cost_give "50"
set ::cost_answer "50"
set ::cost_setvoice "10"
set ::cost_prevanswer "20"
# How many points should be stolen or given?
set ::steal_points "5"
set ::give_points "5"
# How many points should !punish and !reward take/give?
set ::reward_points "5"
set ::punish_points "5"

# How many reports nad recommended questions should be shown in PM?
# Be careful, to high and the bot'll be too busy pasting reports and won't answer other commands
# A web interface to check all is preferred
set ::reports_show "7"
set ::recommend_show "7"

# How many seconds has to pass between each ping command?
set ::s_pinginterval "10"

# Text color:
set ::color_text "00"
# Text background color
set ::color_background "01"
# Color of users nicks
set ::color_nick "09"
# Color of classes
set ::color_class "08"
# Color of answers
set ::color_answer "04"
# Color of numbers in stats
set ::color_statsnumber "04"

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
