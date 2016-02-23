#!/bin/bash
# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

# Plugin parameters value if not define 
LIST_WARNING_THRESHOLD="70"
LIST_CRITICAL_THRESHOLD="80"
INTERVAL_SEC=1
NUM_REPORT=51

CPU_REPORT=`iostat -c $INTERVAL $NUM_REPORT  | sed -e 's/,/./g' | tr -s ' ' ';' | sed '/^$/d' |tail -1`
CPU_REPORT_SECTIONS=`echo ${CPU_REPORT} | grep ';' -o | wc -l`
CPU_USER=`echo $CPU_REPORT | cut -d ";" -f 2`
CPU_SYSTEM=`echo $CPU_REPORT | cut -d ";" -f 4`
# Add for integer shell issue
CPU_USER_MAJOR=`echo $CPU_USER | cut -d "." -f 1`
CPU_SYSTEM_MAJOR=`echo $CPU_SYSTEM | cut -d "." -f 1`
CPU_UTILI_COU=`echo ${CPU_USER} + ${CPU_SYSTEM}|bc`
CPU_UTILI_COUNTER=`echo $CPU_UTILI_COU | cut -d "." -f 1`

# Return
if [ ${CPU_UTILI_COUNTER} -lt ${LIST_WARNING_THRESHOLD} ]
then
    echo "OK - CPUCOU=${CPU_UTILI_COU}% | CPUCOU=${CPU_UTILI_COU}%;80;90"
    exit ${STATE_OK}
fi
if [ ${CPU_UTILI_COUNTER} -gt ${LIST_WARNING_THRESHOLD} -a ${CPU_UTILI_COUNTER} -lt ${LIST_CRITICAL_THRESHOLD} ]
then
    echo "Warning - CPUCOU=${CPU_UTILI_COUNTER}% | CPUCOU=${CPU_UTILI_COUNTER}%;80;90"
    exit ${STATE_WARNING}
fi
if [ ${CPU_UTILI_COUNTER} -gt ${LIST_CRITICAL_THRESHOLD} ]
then
   echo "Critical - CPUCOU=${CPU_UTILI_COUNTER}% | CPUCOU=${CPU_UTILI_COUNTER}%;80;90" 
    exit ${STATE_CRITICAL}
fi
