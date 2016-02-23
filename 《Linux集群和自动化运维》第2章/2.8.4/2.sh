#!/bin/bash
#Nagios plugin For ip connects
#$1 = 15000 $2 = 20000
ip_conns=`netstat -an | grep tcp | grep EST | wc -l`
messages=`netstat -ant | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a, S[a]}'|tr -s '\n' ',' | sed -r 's/(.*),/\1\n/g' `

if [ $ip_conns -lt $1 ]
then
    echo "$messages,OK -connect counts is $ip_conns"
    exit 0
fi
if [ $ip_conns -gt $1 -a $ip_conns -lt $2 ]
then
    echo "$messages,Warning -connect counts is $ip_conns"
    exit 1
fi
if [ $ip_conns -gt $2 ]
then
    echo "$messages,Critical -connect counts is $ip_conns"
    exit 2
fi
