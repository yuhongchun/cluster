#!/bin/bash
#系统基础升级
wget http://mirrors.163.com/.help/CentOS6-Base-163.repo
cd /etc/yum.repos.d/
mv CentOS-Base.repo CentOS-Base.repo.bak
mv CentOS6-Base-163.repo CentOS-Base.repo
yum clean all #清除yum缓存
yum makecache #重建缓存
yum update  #升级Linux系统
#添加epel外部yum扩展源
cd /usr/local/src
wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm
#安装gcc基础库文件以及sysstat工具
yum -y install gcc gcc-c++ vim-enhanced unzip unrar sysstat
#配置ntpdate自动对时
yum -y install ntp
echo "01 01 * * * /usr/sbin/ntpdate ntp.api.bz    >> /dev/null 2>&1" >> /etc/crontab
ntpdate ntp.api.bz
service crond restart
#配置文件的ulimit值
ulimit -SHn 65534
echo "ulimit -SHn 65534" >> /etc/rc.local
cat >> /etc/security/limits.conf << EOF
*                     soft     nofile             65534
*                     hard     nofile             65534
EOF

#基础系统内核优化
cat >> /etc/sysctl.conf << EOF
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_tw_recycle = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65535
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.route.gc_timeout = 100
net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 16384
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_orphans = 16384
EOF
/sbin/sysctl -p

#禁用control-alt-delete组合键以防止误操作
sed -i 's@ca::ctrlaltdel:/sbin/shutdown -t3 -r now@#ca::ctrlaltdel:/sbin/shutdown -t3 -r now@' /etc/inittab
#关闭SElinux
sed -i 's@SELINUX=enforcing@SELINUX=disabled@' /etc/selinux/config
#关闭iptables
service iptables stop
chkconfig iptables off
#ssh服务配置优化,请至少保持机器中至少有一个具有sudo权限的用户，下面的配置会禁止root远程登录
sed -i 's@#PermitRootLogin yes@PermitRootLogin no@' /etc/ssh/sshd_config 
#禁止空密码登录
sed -i 's@#PermitEmptyPasswords no@PermitEmptyPasswords no@' /etc/ssh/sshd_config 
#禁止SSH反向解析
sed -i 's@#UseDNS yes@UseDNS no@' /etc/ssh/sshd_config /etc/ssh/sshd_config
service sshd restart
#禁用ipv6地址
echo "install ipv6 /bin/true" > /etc/modprobe.d/disable-ipv6.conf
#每当系统需要加载IPv6模块时，强制执行/bin/true来代替实际加载的模块
echo "IPV6INIT=no" >> /etc/sysconfig/network-scripts/ifcfg-eth0
#禁用基于IPv6网络，使之不会被触发启动
chkconfig ip6tables off
#vim基础语法优化
cat >> /root/.vimrc << EOF
set number
set ruler
set nohlsearch
set shiftwidth=2
set tabstop=4
set expandtab
set cindent
set autoindent
set mouse=v
syntax on
EOF
#精简开机自启动服务，安装最小化服务的机器初始可以只留crond|network|rsyslog|sshd这四个服务
for i in `chkconfig --list|grep 3:on|awk '{print $1}'`;do chkconfig --level 3 $i off;done
for CURSRV  in crond rsyslog sshd network;do chkconfig --level 3 $CURSRV on;done
#重启服务器
reboot
