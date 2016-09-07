#!/bin/bash
# ==============================================================================
# CPU Utilization Statistics plugin for Nagios 
#
# USAGE     :   ./check_cpu_utili.sh [-w <user,system,iowait>] [-c <user,system,iowait>] ( [ -i <intervals in second> ] [ -n <report number> ])
#           
# Exemple: ./check_cpu_utili.sh 
#          ./check_cpu_utili.sh -w 70,40,30 -c 90,60,40
#          ./check_cpu_utili.sh -w 70,40,30 -c 90,60,40 -i 3 -n 5
#----------------------------------------------------------------------------------------
# Paths to commands used in this script.  These may have to be modified to match your system setup.
IOSTAT="/usr/bin/iostat"

# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin parameters value if not define 
LIST_WARNING_THRESHOLD="70,40,30"
LIST_CRITICAL_THRESHOLD="90,60,40"
INTERVAL_SEC=1
NUM_REPORT=1
# Plugin variable description
PROGNAME=$(basename $0)

if [ ! -x $IOSTAT ]; then
    echo "UNKNOWN: iostat not found or is not executable by the nagios user."
    exit $STATE_UNKNOWN
fi

print_usage() {
        echo ""
        echo "$PROGNAME $RELEASE - CPU Utilization check script for Nagios"
        echo ""
        echo "Usage: check_cpu_utili.sh -w -c (-i -n)"
        echo ""
        echo "  -w  Warning threshold in % for warn_user,warn_system,warn_iowait CPU (default : 70,40,30)"
        echo "  Exit with WARNING status if cpu exceeds warn_n"
        echo "  -c  Critical threshold in % for crit_user,crit_system,crit_iowait CPU (default : 90,60,40)"
        echo "  Exit with CRITICAL status if cpu exceeds crit_n"
        echo "  -i  Interval in seconds for iostat (default : 1)"
        echo "  -n  Number report for iostat (default : 3)"
        echo "  -h  Show this page"
        echo ""
    echo "Usage: $PROGNAME"
    echo "Usage: $PROGNAME --help"
    echo ""
    exit 0
}

print_help() {
    print_usage
        echo ""
        echo "This plugin will check cpu utilization (user,system,CPU_Iowait in %)"
        echo ""
    exit 0
}

# Parse parameters
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_help
            exit $STATE_OK
            ;;
        -v | --version)
                print_release
                exit $STATE_OK
                ;;
        -w | --warning)
                shift
                LIST_WARNING_THRESHOLD=$1
                ;;
        -c | --critical)
               shift
                LIST_CRITICAL_THRESHOLD=$1
                ;;
        -i | --interval)
               shift
               INTERVAL_SEC=$1
                ;;
        -n | --number)
               shift
               NUM_REPORT=$1
                ;;        
        *)  echo "Unknown argument: $1"
            print_usage
            exit $STATE_UNKNOWN
            ;;
        esac
shift
done

# List to Table for warning threshold (compatibility with 
TAB_WARNING_THRESHOLD=(`echo $LIST_WARNING_THRESHOLD | sed 's/,/ /g'`)
if [ "${#TAB_WARNING_THRESHOLD[@]}" -ne "3" ]; then
  echo "ERROR : Bad count parameter in Warning Threshold"
  exit $STATE_WARNING
else  
USER_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[0]}`
SYSTEM_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[1]}`
IOWAIT_WARNING_THRESHOLD=`echo ${TAB_WARNING_THRESHOLD[2]}` 
fi

# List to Table for critical threshold
TAB_CRITICAL_THRESHOLD=(`echo $LIST_CRITICAL_THRESHOLD | sed 's/,/ /g'`)
if [ "${#TAB_CRITICAL_THRESHOLD[@]}" -ne "3" ]; then
  echo "ERROR : Bad count parameter in CRITICAL Threshold"
  exit $STATE_WARNING
else
USER_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[0]}`
SYSTEM_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[1]}`
IOWAIT_CRITICAL_THRESHOLD=`echo ${TAB_CRITICAL_THRESHOLD[2]}`
fi

if [ ${TAB_WARNING_THRESHOLD[0]} -ge ${TAB_CRITICAL_THRESHOLD[0]} -o ${TAB_WARNING_THRESHOLD[1]} -ge ${TAB_CRITICAL_THRESHOLD[1]} -o ${TAB_WARNING_THRESHOLD[2]} -ge ${TAB_CRITICAL_THRESHOLD[2]} ]; then
  echo "ERROR : Critical CPU Threshold lower as Warning CPU Threshold "
  exit $STATE_WARNING
fi

CPU_REPORT=`iostat -c $INTERVAL_SEC $NUM_REPORT | sed -e 's/,/./g' | tr -s ' ' ';' | sed '/^$/d' | tail -1`
CPU_REPORT_SECTIONS=`echo ${CPU_REPORT} | grep ';' -o | wc -l`
CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 2`
CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 4`
CPU_IOWAIT=`echo $CPU_REPORT | cut -d ";" -f 5`
CPU_STEAL=`echo $CPU_REPORT | cut -d ";" -f 6`
CPU_IDLE=`echo $CPU_REPORT | cut -d ";" -f 7`
NAGIOS_STATUS="user=${CPU_USER}%,system=${CPU_SYSTEM}%,iowait=${CPU_IOWAIT}%,idle=${CPU_IDLE}%"
NAGIOS_DATA="CpuUser=${CPU_USER};${TAB_WARNING_THRESHOLD[0]};${TAB_CRITICAL_THRESHOLD[0]};0"

CPU_USER_MAJOR=`echo $CPU_USER| cut -d "." -f 1`
CPU_SYSTEM_MAJOR=`echo $CPU_SYSTEM | cut -d "." -f 1`
CPU_IOWAIT_MAJOR=`echo $CPU_IOWAIT | cut -d "." -f 1`
CPU_IDLE_MAJOR=`echo $CPU_IDLE | cut -d "." -f 1`



# Return
if [ ${CPU_USER_MAJOR} -ge $USER_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_CRITICAL
    elif [ ${CPU_SYSTEM_MAJOR} -ge $SYSTEM_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_CRITICAL
    elif [ ${CPU_IOWAIT_MAJOR} -ge $IOWAIT_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_CRITICAL
    elif [ ${CPU_USER_MAJOR} -ge $USER_WARNING_THRESHOLD ] && [ ${CPU_USER_MAJOR} -lt $USER_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_WARNING 
      elif [ ${CPU_SYSTEM_MAJOR} -ge $SYSTEM_WARNING_THRESHOLD ] && [ ${CPU_SYSTEM_MAJOR} -lt $SYSTEM_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_WARNING 
      elif  [ ${CPU_IOWAIT_MAJOR} -ge $IOWAIT_WARNING_THRESHOLD ] && [ ${CPU_IOWAIT_MAJOR} -lt $IOWAIT_CRITICAL_THRESHOLD ]; then
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_WARNING
else
        echo "CPU STATISTICS OK:${NAGIOS_STATUS} | CPU_USER=${CPU_USER}%;70;90;0;100"
        exit $STATE_OK
fi
