#!/bin/bash

if [ $# -eq 0 ]; then
   echo "Error: please specify logfile."
   exit 0
else
   LOG=$1
fi

if [ ! -f $1 ]; then
   echo "Sorry, sir, I can't find this apache log file, pls try again!"
exit 0
fi

####################################################
echo "Most of the ip:"
echo "-------------------------------------------"
awk '{ print $1 }' $LOG | sort | uniq -c | sort -nr | head -10
echo
echo
####################################################
echo "Most of the time:"
echo "--------------------------------------------"
awk '{ print $4 }' $LOG | cut -c 14-18 | sort | uniq -c | sort -nr | head -10
echo
echo
####################################################
echo "Most of the page:"
echo "--------------------------------------------"
awk '{print $11}' $LOG | sed 's/^.*\（.cn*\）\"/\1/g' | sort | uniq -c | sort -rn | head -10
echo
echo
####################################################
echo "Most of the time / Most of the ip:"
echo "--------------------------------------------"
awk '{ print $4 }' $LOG | cut -c 14-18 | sort -n | uniq -c | sort -nr | head -10 > timelog

for i in `awk '{ print $2 }' timelog`
do
   num=`grep $i timelog | awk '{ print $1 }'`
   echo " $i $num"
   ip=`grep $i $LOG | awk '{ print $1}' | sort -n | uniq -c | sort -nr | head -10`
   echo "$ip"
   echo
done
rm -f timelog
