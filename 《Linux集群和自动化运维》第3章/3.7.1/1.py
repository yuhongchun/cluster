#!/usr/bin/python
# -*- coding: utf-8 -*-
from fabric.api import *
from fabric.colors import * 
from fabric.context_managers import *
#fabric.context_managers是fabric的上下文管理类，这里需要import是因为下面会用到with

env.user = 'root'
env.hosts = ['192.168.1.200','192.168.1.205','192.168.1.206']
env.password = 'bilin101'


@task
#限定只有put_hosts_file函数对fab命令可见。
def put_hosts_files():
   print yellow("rsync /etc/host File")
   with settings(warn_only=True): #出现异常时继续执行，非终止。
       put("/etc/hosts","/etc/hosts")
       print green("rsync file success!")
'''这里用到with是确保即便发生异常，也将尽早执行清理下面的操作，一般来说，Python中的with语句一般多用于执行清理操作（如关闭文件），因为python中打开文件以后的时间是不确定的，如果有其他程序试图访问打开的文件会导致问题。
'''
for host in env.hosts:
    env.host_string = host
    put_hosts_files()
