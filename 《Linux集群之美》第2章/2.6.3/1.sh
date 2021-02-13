#!/bin/bash
while :
do
 nginxpid=`ps -C nginx --no-header | wc -l`
 if [ $nginxpid -eq 0 ];then
    ulimit -SHn 65535
    /usr/local/nginx/sbin/nginx
    sleep 5
   if [ $nginxpid -eq 0 ];then
     /etc/init.d/keepalived stop
   fi
 fi
 sleep 5
done
