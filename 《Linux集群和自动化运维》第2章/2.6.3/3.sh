#!/bin/bash
#check MySQL_Slave Status
#crontab time 00:10
MYSQLPORT=`netstat -na|grep "LISTEN"|grep "3306"|awk -F[:" "]+ '{print $4}'`
MYSQLIP=`ifconfig eth0|grep "inet addr" | awk -F[:" "]+ '{print $4}'`
STATUS=$(/usr/local/webserver/mysql/bin/mysql -u yuhongchun -pyuhongchun101 -S /tmp/mysql.sock -e "show slave status\G" | grep -i "running")
IO_env=`echo  $STATUS | grep IO | awk  ' {print $2}'`
SQL_env=`echo $STATUS | grep SQL | awk  '{print $2}'`


if [ "$MYSQLPORT" == "3306" ]
then
  echo "mysql is running"
else
  mail -s "warn!server: $MYSQLIP mysql is down" yuhongchun027@163.com
fi

if [ "$IO_env" = "Yes" -a "$SQL_env" = "Yes" ]
then
  echo "Slave is running!"
else
  echo "#######  $date  #########">> /data/data/check_mysql_slave.log
  echo "Slave is not running!" >> /data/data/check_mysql_slave.log
  mail -s "warn! $MySQLIP_replicate_error" yuhongchun027@163.com << /data/data/check_mysql_slave.log
fi
