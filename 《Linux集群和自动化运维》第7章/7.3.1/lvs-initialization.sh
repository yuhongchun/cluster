#!/bin/bash
VIP=192.168.1.210
RIP1=192.168.1.205
RIP2=192.168.1.206
. /etc/rc.d/init.d/functions

logger $0 called with $1
case "$1" in
  start)
  echo " Start LVS of DirectorServer"
  /sbin/ifconfig eth0:0 $VIP broadcast $VIP netmask 255.255.255.255 up
  /sbin/route add -host $VIP dev eth0:0
  echo "1" >/proc/sys/net/ipv4/ip_forward
  #Clear ipvsadm table
  /sbin/ipvsadm -C
  #Set LVS rules
  /sbin/ipvsadm -A -t $VIP:80 -s wrr -p 120
  #如果没有-p参数的话，我们等会访问VIP地址时会发现，VIP地址会在后端的两台Web机器上轮流切换
  /sbin/ipvsadm -a -t $VIP:80 -r $RIP1:80 -g
  /sbin/ipvsadm -a -t $VIP:80 -r $RIP2:80 -g
  #Run LVS
  /sbin/ipvsadm
  ;;
stop)
  echo "close LVS Directorserver"
  echo "0" >/proc/sys/net/ipv4/ip_forward
  /sbin/ipvsadm -C
  /sbin/ifconfig eth0:0 down
  ;;
*)
echo "Usage: $0 {start|stop}"
exit 1
esac
