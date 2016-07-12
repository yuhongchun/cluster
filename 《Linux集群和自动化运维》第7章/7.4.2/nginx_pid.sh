#!/bin/bash
while :
do
	nginxpid=`ps -C nginx --no-header | wc -l`
 	if [ $nginxpid -eq 0 ];then
  		/usr/local/nginx/sbin/nginx
  		sleep 5
   			if [ $nginxpid -eq 0 ];then
   				/etc/init.d/keepalived stop
   			fi
 	fi
 	sleep 5
done
