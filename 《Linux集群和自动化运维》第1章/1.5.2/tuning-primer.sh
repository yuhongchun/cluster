#!/bin/sh

# vim: ts=8
#########################################################################
#									#
#	MySQL performance tuning primer script				#
#	Writen by: Matthew Montgomery					#
#	Report bugs to: https://bugs.launchpad.net/mysql-tuning-primer	#
#	Inspired by: MySQLARd (http://gert.sos.be/demo/mysqlar/)	#
#	Version: 1.6-r1		Released: 2011-08-06			#
#	Licenced under GPLv2                                            #
#									#
#########################################################################

#########################################################################
#									#
#	Usage: ./tuning-primer.sh [ mode ] 				#
#									#
#	Available Modes: 						#
#		all : 		perform all checks (default)		#
#		prompt : 	prompt for login credintials and socket	#
#				and execution mode			#
# 		mem, memory : 	run checks for tunable options which	#
#				effect memory usage			#
#		disk, file :	run checks for options which effect	#
#				i/o performance or file handle limits	#
#		innodb :	run InnoDB checks /* to be improved */	# 
#		misc : 		run checks for that don't categorise	#
#				well Slow Queries, Binary logs,		#
#				Used Connections and Worker Threads	#
#########################################################################
#									#
# Set this socket variable ONLY if you have multiple instances running	# 
# or we are unable to find your socket, and you don't want to to be	#
# prompted for input each time you run this script.			#
#									#
#########################################################################
socket=

export black='\033[0m'
export boldblack='\033[1;0m'
export red='\033[31m'
export boldred='\033[1;31m'
export green='\033[32m'
export boldgreen='\033[1;32m'
export yellow='\033[33m'
export boldyellow='\033[1;33m'
export blue='\033[34m'
export boldblue='\033[1;34m'
export magenta='\033[35m'
export boldmagenta='\033[1;35m'
export cyan='\033[36m'
export boldcyan='\033[1;36m'
export white='\033[37m'
export boldwhite='\033[1;37m'


cecho ()

## -- Function to easliy print colored text -- ##
	
	# Color-echo.
	# Argument $1 = message
	# Argument $2 = color
{
local default_msg="No message passed."

message=${1:-$default_msg}	# Defaults to default message.

#change it for fun
#We use pure names
color=${2:-black}		# Defaults to black, if not specified.

case $color in
	black)
		 printf "$black" ;;
	boldblack)
		 printf "$boldblack" ;;
	red)
		 printf "$red" ;;
	boldred)
		 printf "$boldred" ;;
	green)
		 printf "$green" ;;
	boldgreen)
		 printf "$boldgreen" ;;
	yellow)
		 printf "$yellow" ;;
	boldyellow)
		 printf "$boldyellow" ;;
	blue)
		 printf "$blue" ;;
	boldblue)
		 printf "$boldblue" ;;
	magenta)
		 printf "$magenta" ;;
	boldmagenta)
		 printf "$boldmagenta" ;;
	cyan)
		 printf "$cyan" ;;
	boldcyan)
		 printf "$boldcyan" ;;
	white)
		 printf "$white" ;;
	boldwhite)
		 printf "$boldwhite" ;;
esac
  printf "%s\n"  "$message"
  tput sgr0			# Reset to normal.
  printf "$black"

return
}


cechon ()		

## -- Function to easliy print colored text -- ##

	# Color-echo.
	# Argument $1 = message
	# Argument $2 = color
{
local default_msg="No message passed."
				# Doesn't really need to be a local variable.

message=${1:-$default_msg}	# Defaults to default message.

#change it for fun
#We use pure names
color=${2:-black}		# Defaults to black, if not specified.

case $color in
	black)
		printf "$black" ;;
	boldblack)
		printf "$boldblack" ;;
	red)
		printf "$red" ;;
	boldred)
		printf "$boldred" ;;
	green)
		printf "$green" ;;
	boldgreen)
		printf "$boldgreen" ;;
	yellow)
		printf "$yellow" ;;
	boldyellow)
		printf "$boldyellow" ;;
	blue)
		printf "$blue" ;;
	boldblue)
		printf "$boldblue" ;;
	magenta)
		printf "$magenta" ;;
	boldmagenta)
		printf "$boldmagenta" ;;
	cyan)
		printf "$cyan" ;;
	boldcyan)
		printf "$boldcyan" ;;
	white)
		printf "$white" ;;
	boldwhite)
		printf "$boldwhite" ;;
esac
  printf "%s"  "$message"
  tput sgr0			# Reset to normal.
  printf "$black"

return
}


print_banner () {

## -- Banner -- ##

cecho "	-- MYSQL PERFORMANCE TUNING PRIMER --" boldblue
cecho "	     - By: Matthew Montgomery -" black

}

## -- Find the location of the mysql.sock file -- ##

check_for_socket () {
	if [ -z "$socket" ] ; then
		# Use ~/my.cnf version
		if [ -f ~/.my.cnf ] ; then
			cnf_socket=$(grep ^socket ~/.my.cnf | awk -F \= '{ print $2 }' | head -1)
		fi
		if [ -S "$cnf_socket" ] ; then
			socket=$cnf_socket
		elif [ -S /var/lib/mysql/mysql.sock ] ; then
			socket=/var/lib/mysql/mysql.sock
		elif [ -S /var/run/mysqld/mysqld.sock ] ; then
			socket=/var/run/mysqld/mysqld.sock
		elif [ -S /tmp/mysql.sock ] ; then
			socket=/tmp/mysql.sock
		else
			if [ -S "$ps_socket" ] ; then
			socket=$ps_socket
			fi
		fi
	fi
	if [ -S "$socket" ] ; then
		echo UP > /dev/null
	else
		cecho "No valid socket file \"$socket\" found!" boldred
		cecho "The mysqld process is not running or it is installed in a custom location." red
		cecho "If you are sure mysqld is running, execute script in \"prompt\" mode or set " red
		cecho "the socket= variable at the top of this script" red
		exit 1
	fi
}


check_for_plesk_passwords () {

## -- Check for the existance of plesk and login using it's credentials -- ##

	if [ -f /etc/psa/.psa.shadow ] ; then
	        mysql="mysql -S $socket -u admin -p$(cat /etc/psa/.psa.shadow)"
	        mysqladmin="mysqladmin -S $socket -u admin -p$(cat /etc/psa/.psa.shadow)"
	else
	        mysql="mysql"
	        mysqladmin="mysqladmin"
	        # mysql="mysql -S $socket"
	        # mysqladmin="mysqladmin -S $socket"
	fi
}

check_mysql_login () {

## -- Test for running mysql -- ##

	is_up=$($mysqladmin ping 2>&1)
	if [ "$is_up" = "mysqld is alive" ] ; then
		echo UP > /dev/null
	 	# echo $is_up
	elif [ "$is_up" != "mysqld is alive" ] ; then
		printf "\n"
		cecho "Using login values from ~/.my.cnf" 
		cecho "- INITIAL LOGIN ATTEMPT FAILED -" boldred
		if [ -z $prompted ] ; then
		find_webmin_passwords
		else
			return 1
		fi
		
	else 
		cecho "Unknow exit status" red
		exit -1
	fi
}

final_login_attempt () {
        is_up=$($mysqladmin ping 2>&1)
        if [ "$is_up" = "mysqld is alive" ] ; then
                echo UP > /dev/null
        elif [ "$is_up" != "mysqld is alive" ] ; then
                cecho "- FINAL LOGIN ATTEMPT FAILED -" boldred
		cecho "Unable to log into socket: $socket" boldred
                exit 1
        fi
}

second_login_failed () {

## -- create a ~/.my.cnf and exit when all else fails -- ##

	cecho "Could not auto detect login info!"
	cecho "Found potential sockets: $found_socks"
	cecho "Using: $socket" red
	read -p "Would you like to provide a different socket?: [y/N] " REPLY
		case $REPLY in 
			yes | y | Y | YES)
			read -p "Socket: " socket
			;;
		esac
	read -p "Do you have your login handy ? [y/N] : " REPLY
	case $REPLY in 
		yes | y | Y | YES)
		answer1='yes'
		read -p "User: " user
		read -rp "Password: " pass
		if [ -z $pass ] ; then
		export mysql="$mysql -S$socket -u$user"
		export mysqladmin="$mysqladmin -S$socket -u$user"
		else
		export mysql="$mysql -S$socket -u$user -p$pass"
		export mysqladmin="$mysqladmin -S$socket -u$user -p$pass"
		fi
		;;
		*)
		cecho "Please create a valid login to MySQL"
		cecho "Or, set correct values for  'user=' and 'password=' in ~/.my.cnf"
		;;
	esac
	cecho " "
	read -p "Would you like me to create a ~/.my.cnf file for you? [y/N] : " REPLY
        case $REPLY in
	        yes | y | Y | YES)
		answer2='yes'
		if [ ! -f ~/.my.cnf ] ; then
			umask 077
			printf "[client]\nuser=$user\npassword=$pass\nsocket=$socket" > ~/.my.cnf
			if [ "$answer1" != 'yes' ] ; then
				exit 1
			else
				final_login_attempt
				return 0
			fi
		else
			printf "\n"
			cecho "~/.my.cnf already exists!" boldred
			printf "\n"
			read -p "Replace ? [y/N] : " REPLY
			if [ "$REPLY" = 'y' ] || [ "$REPLY" = 'Y' ] ; then 
			printf "[client]\nuser=$user\npassword=$pass\socket=$socket" > ~/.my.cnf
				if [ "$answer1" != 'yes' ] ; then
					exit 1
				else
					final_login_attempt
					return 0
				fi
			else
				cecho "Please set the 'user=' and 'password=' and 'socket=' values in ~/.my.cnf"
				exit 1
			fi
		fi
		;;
		*)
		if [ "$answer1" != 'yes' ] ; then
			exit 1
		else
			final_login_attempt
			return 0
		fi
		;;
	esac
}

find_webmin_passwords () {

## -- populate the .my.cnf file using values harvested from Webmin -- ##

	cecho "Testing for stored webmin passwords:"
	if [ -f /etc/webmin/mysql/config ] ; then
		user=$(grep ^login= /etc/webmin/mysql/config | cut -d "=" -f 2)
		pass=$(grep ^pass= /etc/webmin/mysql/config | cut -d "=" -f 2)
		if [  $user ] && [ $pass ] && [ ! -f ~/.my.cnf  ] ; then
			cecho "Setting login info as User: $user Password: $pass"
			touch ~/.my.cnf
			chmod 600 ~/.my.cnf
			printf "[client]\nuser=$user\npassword=$pass" > ~/.my.cnf 
			cecho "Retrying login"
			is_up=$($mysqladmin ping 2>&1)
			if [ "$is_up" = "mysqld is alive"  ] ; then
				echo UP > /dev/null
			else
				second_login_failed
			fi
		echo
		else
			second_login_failed
		echo
		fi
	else
	cecho " None Found" boldred
		second_login_failed
	fi
}

#########################################################################
#									#
#  Function to pull MySQL status variable				#
#									#
#  Call using :								#
#	mysql_status \'Mysql_status_variable\' bash_dest_variable	#
#									#
#########################################################################

mysql_status () {
	local status=$($mysql -Bse "show /*!50000 global */ status like $1" | awk '{ print $2 }')
	export "$2"=$status
}

#########################################################################
#									#
#  Function to pull MySQL server runtime variable			#
#									#
#  Call using :								#
#	mysql_variable \'Mysql_server_variable\' bash_dest_variable	#
#	- OR -								#
#	mysql_variableTSV \'Mysql_server_variable\' bash_dest_variable	#
#									#
#########################################################################

mysql_variable () {
	local variable=$($mysql -Bse "show /*!50000 global */ variables like $1" | awk '{ print $2 }')
	export "$2"=$variable
}
mysql_variableTSV () {
        local variable=$($mysql -Bse "show /*!50000 global */ variables like $1" | awk -F \t '{ print $2 }')
        export "$2"=$variable
}

float2int () {
        local variable=$(echo "$1 / 1" | bc -l)
        export "$2"=$variable
}

divide () {

# -- Divide two intigers -- #

	usage="$0 dividend divisor '$variable' scale"
	if [ $1 -ge 1 ]	; then
		dividend=$1
	else
		cecho "Invalid Dividend" red
		echo $usage
		exit 1
	fi
	if [ $2 -ge 1 ] ; then
		divisor=$2
	else
		cecho "Invalid Divisor" red
		echo $usage
		exit 1
	fi
	if [ ! -n $3 ] ; then
		cecho "Invalid variable name" red
		echo $usage
		exit 1
	fi
	if [ -z $4 ] ; then
		scale=2
	elif [ $4 -ge 0 ] ; then
		scale=$4
	else
		cecho "Invalid scale" red
		echo $usage
		exit 1
	fi
	export $3=$(echo "scale=$scale; $dividend / $divisor" | bc -l)
}

human_readable () {

#########################################################################
#									#
#  Convert a value in to human readable size and populate a variable	#
#  with the result.							#
#									#
#  Call using:								#
#	human_readable $value 'variable name' [ places of precision]	#
#									#
#########################################################################

	## value=$1
	## variable=$2
	scale=$3

	if [ $1 -ge 1073741824 ] ; then
		if [ -z $3 ] ; then
			scale=2
		fi
		divide $1 1073741824 "$2" $scale
		unit="G"
	elif [ $1 -ge 1048576 ] ; then
		if [ -z $3 ] ; then 
			scale=0
		fi
		divide $1 1048576 "$2" $scale
	        unit="M"
	elif [ $1 -ge 1024 ] ; then
		if [ -z $3 ] ; then
			scale=0
		fi
		divide $1 1024 "$2" $scale
	        unit="K"
	else
		export "$2"=$1
	        unit="bytes"
	fi
	# let "$2"=$HR
}

human_readable_time () {

########################################################################
#								       #
#	Function to produce human readable time                        #
#								       #
########################################################################

	usage="$0 seconds 'variable'"
	if [ -z $1 ] || [ -z $2 ] ; then
		cecho $usage red
		exit 1
	fi
	days=$(echo "scale=0 ; $1 / 86400" | bc -l)
	remainder=$(echo "scale=0 ; $1 % 86400" | bc -l)
	hours=$(echo "scale=0 ; $remainder / 3600" | bc -l)
	remainder=$(echo "scale=0 ; $remainder % 3600" | bc -l)
	minutes=$(echo "scale=0 ; $remainder / 60" | bc -l)
	seconds=$(echo "scale=0 ; $remainder % 60" | bc -l)
	export $2="$days days $hours hrs $minutes min $seconds sec"
}

check_mysql_version () {

## -- Print Version Info -- ##

	mysql_variable \'version\' mysql_version
	mysql_variable \'version_compile_machine\' mysql_version_compile_machine
	
if [ "$mysql_version_num" -lt 050000 ]; then
	cecho "MySQL Version $mysql_version $mysql_version_compile_machine is EOL please upgrade to MySQL 4.1 or later" boldred
else
	cecho "MySQL Version $mysql_version $mysql_version_compile_machine"
fi


}

post_uptime_warning () {

#########################################################################
#									#
#  Present a reminder that mysql must run for a couple of days to	#
#  build up good numbers in server status variables before these tuning	#
#  suggestions should be used.						#
#									#
#########################################################################

	mysql_status \'Uptime\' uptime
	mysql_status \'Threads_connected\' threads
	queries_per_sec=$(($questions/$uptime))
	human_readable_time $uptime uptimeHR

	cecho "Uptime = $uptimeHR"
	cecho "Avg. qps = $queries_per_sec"
	cecho "Total Questions = $questions"
	cecho "Threads Connected = $threads"
	echo

	if [ $uptime -gt 172800 ] ; then
		cecho "Server has been running for over 48hrs."
		cecho "It should be safe to follow these recommendations"
	else
		cechon "Warning: " boldred
		cecho "Server has not been running for at least 48hrs." boldred
		cecho "It may not be safe to use these recommendations" boldred

	fi
	echo ""
	cecho "To find out more information on how each of these" red
	cecho "runtime variables effects performance visit:" red
	if [ "$major_version" = '3.23' ] || [ "$major_version" = '4.0' ] || [ "$major_version" = '4.1' ] ; then
	cecho "http://dev.mysql.com/doc/refman/4.1/en/server-system-variables.html" boldblue
	elif [ "$major_version" = '5.0' ] || [ "$mysql_version_num" -gt '050100' ]; then
	cecho "http://dev.mysql.com/doc/refman/$major_version/en/server-system-variables.html" boldblue	
	else
	cecho "UNSUPPORTED MYSQL VERSION" boldred
	exit 1
	fi
	cecho "Visit http://www.mysql.com/products/enterprise/advisors.html" boldblue
	cecho "for info about MySQL's Enterprise Monitoring and Advisory Service" boldblue
}

check_slow_queries () {

## -- Slow Queries -- ## 

	cecho "SLOW QUERIES" boldblue

	mysql_status \'Slow_queries\' slow_queries
	mysql_variable \'long_query_time\' long_query_time
	mysql_variable \'log%queries\' log_slow_queries
	
	prefered_query_time=5
	if [ -e /etc/my.cnf ] ; then
		if [ -z $log_slow_queries ] ; then
			log_slow_queries=$(grep log-slow-queries /etc/my.cnf)
		fi
	fi

	if [ "$log_slow_queries" = 'ON' ] ; then
		cecho "The slow query log is enabled."
	elif [ "$log_slow_queries" = 'OFF' ] ; then
		cechon "The slow query log is "
		cechon "NOT" boldred
		cecho " enabled."
	elif [ -z $log_slow_queries ] ; then
		cechon "The slow query log is "
		cechon "NOT" boldred
		cecho " enabled."
	else
		cecho "Error: $log_slow_queries" boldred
	fi
	cecho "Current long_query_time = $long_query_time sec."
	cechon "You have "
	cechon "$slow_queries" boldred 
	cechon " out of "
	cechon "$questions" boldred
	cecho " that take longer than $long_query_time sec. to complete"
	
	float2int long_query_time long_query_timeInt

	if [ $long_query_timeInt -gt $prefered_query_time ] ; then
                cecho "Your long_query_time may be too high, I typically set this under $prefered_query_time sec." red
	else
		cecho "Your long_query_time seems to be fine" green
	fi 

}

check_binary_log () {

## -- Binary Log -- ##

	cecho "BINARY UPDATE LOG" boldblue

	mysql_variable \'log_bin\' log_bin
	mysql_variable \'max_binlog_size\' max_binlog_size
	mysql_variable \'expire_logs_days\' expire_logs_days
	mysql_variable \'sync_binlog\' sync_binlog
	#  mysql_variable \'max_binlog_cache_size\' max_binlog_cache_size

	if [ "$log_bin" = 'ON' ] ; then
		cecho "The binary update log is enabled"
		if [ -z "$max_binlog_size" ] ; then
			cecho "The max_binlog_size is not set. The binary log will rotate when it reaches 1GB." red
		fi
		if [ "$expire_logs_days" -eq 0 ] ; then
			cecho "The expire_logs_days is not set." boldred
			cechon "The mysqld will retain the entire binary log until " red
			cecho "RESET MASTER or PURGE MASTER LOGS commands are run manually" red
			cecho "Setting expire_logs_days will allow you to remove old binary logs automatically"  yellow
			cecho "See http://dev.mysql.com/doc/refman/$major_version/en/purge-master-logs.html" yellow
		fi
		if [ "$sync_binlog" = 0 ] ; then
			cecho "Binlog sync is not enabled, you could loose binlog records during a server crash" red
		fi
	else
		cechon "The binary update log is "
		cechon "NOT " boldred
		cecho "enabled."
		cecho "You will not be able to do point in time recovery" red
		cecho "See http://dev.mysql.com/doc/refman/$major_version/en/point-in-time-recovery.html" yellow
	fi
}

check_used_connections () {

## -- Used Connections -- ##

	mysql_variable \'max_connections\' max_connections
	mysql_status \'Max_used_connections\' max_used_connections
	mysql_status \'Threads_connected\' threads_connected

	connections_ratio=$(($max_used_connections*100/$max_connections))

	cecho "MAX CONNECTIONS" boldblue
	cecho "Current max_connections = $max_connections"
	cecho "Current threads_connected = $threads_connected"
	cecho "Historic max_used_connections = $max_used_connections"
	cechon "The number of used connections is "
	if [ $connections_ratio -ge 85 ] ; then
		txt_color=red
		error=1
	elif [ $connections_ratio -le 10 ] ; then
		txt_color=red
		error=2
	else
		txt_color=green
		error=0
	fi
	# cechon "$max_used_connections " $txt_color
	# cechon "which is "
	cechon "$connections_ratio% " $txt_color
	cecho "of the configured maximum."

	if [ $error -eq 1 ] ; then
		cecho "You should raise max_connections" $txt_color
	elif [ $error -eq 2 ] ; then
		cecho "You are using less than 10% of your configured max_connections." $txt_color
		cecho "Lowering max_connections could help to avoid an over-allocation of memory" $txt_color
		cecho "See \"MEMORY USAGE\" section to make sure you are not over-allocating" $txt_color
	else 
		cecho "Your max_connections variable seems to be fine." $txt_color
	fi
	unset txt_color
}

check_threads() {

## -- Worker Threads -- ##

	cecho "WORKER THREADS" boldblue

	mysql_status \'Threads_created\' threads_created1
	sleep 1
	mysql_status \'Threads_created\' threads_created2

	mysql_status \'Threads_cached\' threads_cached
	mysql_status \'Uptime\' uptime
	mysql_variable \'thread_cache_size\' thread_cache_size

	historic_threads_per_sec=$(($threads_created1/$uptime))
	current_threads_per_sec=$(($threads_created2-$threads_created1))

	cecho "Current thread_cache_size = $thread_cache_size"
	cecho "Current threads_cached = $threads_cached"
	cecho "Current threads_per_sec = $current_threads_per_sec"
	cecho "Historic threads_per_sec = $historic_threads_per_sec"

	if [ $historic_threads_per_sec -ge 2 ] && [ $threads_cached -le 1 ] ; then
		cecho "Threads created per/sec are overrunning threads cached" red
		cecho "You should raise thread_cache_size" red
	elif [ $current_threads_per_sec -ge 2 ] ; then
		cecho "Threads created per/sec are overrunning threads cached" red
		cecho "You should raise thread_cache_size" red
	else
		cecho "Your thread_cache_size is fine" green
	fi
}

check_key_buffer_size () {

## -- Key buffer Size -- ##

	cecho "KEY BUFFER" boldblue

	mysql_status \'Key_read_requests\' key_read_requests
	mysql_status \'Key_reads\' key_reads
	mysql_status \'Key_blocks_used\' key_blocks_used
	mysql_status \'Key_blocks_unused\' key_blocks_unused
	mysql_variable \'key_cache_block_size\' key_cache_block_size
	mysql_variable \'key_buffer_size\' key_buffer_size
        mysql_variable \'datadir\' datadir
        mysql_variable \'version_compile_machine\' mysql_version_compile_machine
	myisam_indexes=$($mysql -Bse "/*!50000 SELECT IFNULL(SUM(INDEX_LENGTH),0) from information_schema.TABLES where ENGINE='MyISAM' */")

	if [ -z $myisam_indexes ] ; then
		myisam_indexes=$(find $datadir -name '*.MYI' -exec du $duflags '{}' \; 2>&1 | awk '{ s += $1 } END { printf("%.0f\n", s )}')
	fi

        if [ $key_reads -eq 0 ] ; then
                cecho "No key reads?!" boldred
                cecho "Seriously look into using some indexes" red
                key_cache_miss_rate=0
                key_buffer_free=$(echo "$key_blocks_unused * $key_cache_block_size / $key_buffer_size * 100" | bc -l )
                key_buffer_freeRND=$(echo "scale=0; $key_buffer_free / 1" | bc -l)
        else
                key_cache_miss_rate=$(($key_read_requests/$key_reads))
                if [ ! -z $key_blocks_unused ] ; then
			key_buffer_free=$(echo "$key_blocks_unused * $key_cache_block_size / $key_buffer_size * 100" | bc -l )
                	key_buffer_freeRND=$(echo "scale=0; $key_buffer_free / 1" | bc -l)
                else
                        key_buffer_free='Unknown'
                        key_buffer_freeRND=75
                fi
        fi

	human_readable $myisam_indexes myisam_indexesHR
	cecho "Current MyISAM index space = $myisam_indexesHR $unit" 

	human_readable  $key_buffer_size key_buffer_sizeHR
	cecho "Current key_buffer_size = $key_buffer_sizeHR $unit"
	cecho "Key cache miss rate is 1 : $key_cache_miss_rate"
	cecho "Key buffer free ratio = $key_buffer_freeRND %" 

	if [ "$major_version" = '5.1' ] && [ $mysql_version_num -lt 050123 ] ; then
		if [ $key_buffer_size -ge 4294967296 ] && ( echo "x86_64 ppc64 ia64 sparc64 i686" | grep -q $mysql_version_compile_machine ) ; then
			cecho "Using key_buffer_size > 4GB will cause instability in versions prior to 5.1.23 " boldred
			cecho "See Bug#5731, Bug#29419, Bug#29446" boldred
		fi
	fi
	if [ "$major_version" = '5.0' ] && [ $mysql_version_num -lt 050052 ] ; then
		if [ $key_buffer_size -ge 4294967296 ] && ( echo "x86_64 ppc64 ia64 sparc64 i686" | grep -q $mysql_version_compile_machine ) ; then
			cecho "Using key_buffer_size > 4GB will cause instability in versions prior to 5.0.52 " boldred
			cecho "See Bug#5731, Bug#29419, Bug#29446" boldred
		fi
	fi
	if [ "$major_version" = '4.1' -o "$major_version" = '4.0' ] && [ $key_buffer_size -ge 4294967296 ] && ( echo "x86_64 ppc64 ia64 sparc64 i686" | grep -q $mysql_version_compile_machine ) ; then
		cecho "Using key_buffer_size > 4GB will cause instability in versions prior to 5.0.52 " boldred
		cecho "Reduce key_buffer_size to a safe value" boldred
		cecho "See Bug#5731, Bug#29419, Bug#29446" boldred
	fi

	if [ $key_cache_miss_rate -le 100 ] && [ $key_cache_miss_rate -gt 0 ] && [ $key_buffer_freeRND -le 20 ]; then
		cecho "You could increase key_buffer_size" boldred
		cecho "It is safe to raise this up to 1/4 of total system memory;"
		cecho "assuming this is a dedicated database server."
	elif [ $key_buffer_freeRND -le 20 ] && [ $key_buffer_size -le $myisam_indexes ] ; then
		cecho "You could increase key_buffer_size" boldred
		cecho "It is safe to raise this up to 1/4 of total system memory;"
		cecho "assuming this is a dedicated database server."
	elif [ $key_cache_miss_rate -ge 10000 ] || [ $key_buffer_freeRND -le 50  ] ; then
		cecho "Your key_buffer_size seems to be too high." red 
		cecho "Perhaps you can use these resources elsewhere" red
	else
		cecho "Your key_buffer_size seems to be fine" green
	fi
}

check_query_cache () {

## -- Query Cache -- ##

	cecho "QUERY CACHE" boldblue

	mysql_variable \'version\' mysql_version
	mysql_variable \'query_cache_size\' query_cache_size
	mysql_variable \'query_cache_limit\' query_cache_limit
	mysql_variable \'query_cache_min_res_unit\' query_cache_min_res_unit
	mysql_status \'Qcache_free_memory\' qcache_free_memory
	mysql_status \'Qcache_total_blocks\' qcache_total_blocks
	mysql_status \'Qcache_free_blocks\' qcache_free_blocks
	mysql_status \'Qcache_lowmem_prunes\' qcache_lowmem_prunes

	if [ -z $query_cache_size ] ; then
		cecho "You are using MySQL $mysql_version, no query cache is supported." red
		cecho "I recommend an upgrade to MySQL 4.1 or better" red
	elif [ $query_cache_size -eq 0 ] ; then
		cecho "Query cache is supported but not enabled" red
		cecho "Perhaps you should set the query_cache_size" red
	else
		qcache_used_memory=$(($query_cache_size-$qcache_free_memory))
		qcache_mem_fill_ratio=$(echo "scale=2; $qcache_used_memory * 100 / $query_cache_size" | bc -l)
		qcache_mem_fill_ratioHR=$(echo "scale=0; $qcache_mem_fill_ratio / 1" | bc -l)

		cecho "Query cache is enabled" green
		human_readable $query_cache_size query_cache_sizeHR
		cecho "Current query_cache_size = $query_cache_sizeHR $unit"
		human_readable $qcache_used_memory qcache_used_memoryHR
		cecho "Current query_cache_used = $qcache_used_memoryHR $unit"
		human_readable $query_cache_limit query_cache_limitHR
		cecho "Current query_cache_limit = $query_cache_limitHR $unit"
		cecho "Current Query cache Memory fill ratio = $qcache_mem_fill_ratio %"
		if [ -z $query_cache_min_res_unit ] ; then
			cecho "No query_cache_min_res_unit is defined.  Using MySQL < 4.1 cache fragmentation can be inpredictable" %yellow
		else
			human_readable $query_cache_min_res_unit query_cache_min_res_unitHR 
			cecho "Current query_cache_min_res_unit = $query_cache_min_res_unitHR $unit"
		fi
		if [ $qcache_free_blocks -gt 2 ] && [ $qcache_total_blocks -gt 0 ] ; then
			qcache_percent_fragmented=$(echo "scale=2; $qcache_free_blocks * 100 / $qcache_total_blocks" | bc -l)
			qcache_percent_fragmentedHR=$(echo "scale=0; $qcache_percent_fragmented / 1" | bc -l)
			if [ $qcache_percent_fragmentedHR -gt 20 ] ; then
				cecho "Query Cache is $qcache_percent_fragmentedHR % fragmented" red
				cecho "Run \"FLUSH QUERY CACHE\" periodically to defragment the query cache memory" red 
				cecho "If you have many small queries lower 'query_cache_min_res_unit' to reduce fragmentation." red
			fi
		fi

		if [ $qcache_mem_fill_ratioHR -le 25 ] ; then
        	        cecho "Your query_cache_size seems to be too high." red
	                cecho "Perhaps you can use these resources elsewhere" red
		fi
		if [ $qcache_lowmem_prunes -ge 50 ] && [ $qcache_mem_fill_ratioHR -ge 80 ]; then
			cechon "However, "
			cechon "$qcache_lowmem_prunes " boldred
			cecho "queries have been removed from the query cache due to lack of memory"
			cecho "Perhaps you should raise query_cache_size" boldred
		fi
		cecho "MySQL won't cache query results that are larger than query_cache_limit in size" yellow
	fi

}

check_sort_operations () {

## -- Sort Operations -- ##

	cecho "SORT OPERATIONS" boldblue

	mysql_status \'Sort_merge_passes\' sort_merge_passes
	mysql_status \'Sort_scan\' sort_scan
	mysql_status \'Sort_range\' sort_range
	mysql_variable \'sort_buffer%\' sort_buffer_size 
	mysql_variable \'read_rnd_buffer_size\' read_rnd_buffer_size 

	total_sorts=$(($sort_scan+$sort_range))
	if [ -z $read_rnd_buffer_size ] ; then
		mysql_variable \'record_buffer\' read_rnd_buffer_size
	fi

	## Correct for rounding error in mysqld where 512K != 524288 ##
	sort_buffer_size=$(($sort_buffer_size+8))
	read_rnd_buffer_size=$(($read_rnd_buffer_size+8))

	human_readable $sort_buffer_size sort_buffer_sizeHR
	cecho "Current sort_buffer_size = $sort_buffer_sizeHR $unit"

	human_readable $read_rnd_buffer_size read_rnd_buffer_sizeHR
	cechon "Current " 
	if [ "$major_version" = '3.23' ] ; then
		cechon "record_rnd_buffer "
	else
		cechon "read_rnd_buffer_size "
	fi
	cecho "= $read_rnd_buffer_sizeHR $unit"

	if [ $total_sorts -eq 0 ] ; then 
		cecho "No sort operations have been performed"
		passes_per_sort=0
	fi
	if [ $sort_merge_passes -ne 0 ] ; then
		passes_per_sort=$(($sort_merge_passes/$total_sorts))
	else
		passes_per_sort=0
	fi

	if [ $passes_per_sort -ge 2 ] ; then
		cechon "On average "
		cechon "$passes_per_sort " boldred
		cecho "sort merge passes are made per sort operation"
		cecho "You should raise your sort_buffer_size"
		cechon "You should also raise your "
		if [ "$major_version" = '3.23' ] ; then 
			cecho "record_rnd_buffer_size"
		else
			cecho "read_rnd_buffer_size"
		fi
	else
		cecho "Sort buffer seems to be fine" green
	fi
}

check_join_operations () {

## -- Joins -- ##

	cecho "JOINS" boldblue

	mysql_status \'Select_full_join\' select_full_join
	mysql_status \'Select_range_check\' select_range_check
	mysql_variable \'join_buffer%\' join_buffer_size
	
	## Some 4K is dropped from join_buffer_size adding it back to make sane ##
	## handling of human-readable conversion ## 

	join_buffer_size=$(($join_buffer_size+4096))

	human_readable $join_buffer_size join_buffer_sizeHR 2

	cecho "Current join_buffer_size = $join_buffer_sizeHR $unit"
	cecho "You have had $select_full_join queries where a join could not use an index properly"

	if [ $select_range_check -eq 0 ] && [ $select_full_join -eq 0 ] ; then
		cecho "Your joins seem to be using indexes properly" green
	fi
	if [ $select_full_join -gt 0 ] ; then
		print_error='true'
		raise_buffer='true'
	fi
	if [ $select_range_check -gt 0 ] ; then
		cecho "You have had $select_range_check joins without keys that check for key usage after each row" red
		print_error='true'
		raise_buffer='true'
	fi

	## For Debuging ##
	# print_error='true'
	if [ $join_buffer_size -ge 4194304 ] ; then
		cecho "join_buffer_size >= 4 M" boldred
		cecho "This is not advised" boldred
		raise_buffer=
	fi

	if [ $print_error ] ; then 
		if [ "$major_version" = '3.23' ] || [ "$major_version" = '4.0' ] ; then
			cecho "You should enable \"log-long-format\" "
		elif [ "$mysql_version_num" -gt 040100 ]; then
			cecho "You should enable \"log-queries-not-using-indexes\""
		fi
		cecho "Then look for non indexed joins in the slow query log."
		if [ $raise_buffer ] ; then
		cecho "If you are unable to optimize your queries you may want to increase your"
		cecho "join_buffer_size to accommodate larger joins in one pass."
		printf "\n"
		cecho "Note! This script will still suggest raising the join_buffer_size when" boldred
		cecho "ANY joins not using indexes are found." boldred
		fi
	fi

	# XXX Add better tests for join_buffer_size pending mysql bug #15088  XXX #
}

check_tmp_tables () {

## -- Temp Tables -- ##

	cecho "TEMP TABLES" boldblue

	mysql_status \'Created_tmp_tables\' created_tmp_tables 
	mysql_status \'Created_tmp_disk_tables\' created_tmp_disk_tables
	mysql_variable \'tmp_table_size\' tmp_table_size
	mysql_variable \'max_heap_table_size\' max_heap_table_size


	if [ $created_tmp_tables -eq 0 ] ; then
		tmp_disk_tables=0
	else
		tmp_disk_tables=$((created_tmp_disk_tables*100/(created_tmp_tables+created_tmp_disk_tables)))
	fi
	human_readable $max_heap_table_size max_heap_table_sizeHR
	cecho "Current max_heap_table_size = $max_heap_table_sizeHR $unit"

	human_readable $tmp_table_size tmp_table_sizeHR 
	cecho "Current tmp_table_size = $tmp_table_sizeHR $unit"

	cecho "Of $created_tmp_tables temp tables, $tmp_disk_tables% were created on disk"
	if [ $tmp_table_size -gt $max_heap_table_size ] ; then
		cecho "Effective in-memory tmp_table_size is limited to max_heap_table_size." yellow
	fi
	if [ $tmp_disk_tables -ge 25 ] ; then
		cecho "Perhaps you should increase your tmp_table_size and/or max_heap_table_size" boldred
		cecho "to reduce the number of disk-based temporary tables" boldred
		cecho "Note! BLOB and TEXT columns are not allow in memory tables." yellow
		cecho "If you are using these columns raising these values might not impact your " yellow
		cecho  "ratio of on disk temp tables." yellow
	else
		cecho "Created disk tmp tables ratio seems fine" green
	fi
}

check_open_files () {

## -- Open Files Limit -- ## 
	cecho "OPEN FILES LIMIT" boldblue

	mysql_variable \'open_files_limit\' open_files_limit
	mysql_status   \'Open_files\' open_files
	
	if [ -z $open_files_limit ] || [ $open_files_limit -eq 0 ] ; then
		open_files_limit=$(ulimit -n)
		cant_override=1
	else
		cant_override=0
	fi
	cecho "Current open_files_limit = $open_files_limit files"
	
	open_files_ratio=$(($open_files*100/$open_files_limit))

	cecho "The open_files_limit should typically be set to at least 2x-3x" yellow 
	cecho "that of table_cache if you have heavy MyISAM usage." yellow
	if [ $open_files_ratio -ge 75 ] ; then
		cecho "You currently have open more than 75% of your open_files_limit" boldred
		if [ $cant_override -eq 1 ] ; then
			cecho "You sh