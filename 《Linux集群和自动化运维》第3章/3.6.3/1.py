#!/usr/bin/python
# -*- coding: utf-8 -*-
from fabric.api import *
from fabric.colors import *

env.user = "root" #定义用户名，env对象的作用是定义fabric指定文件的全局设定
env.password = "redhat" #定义密码
env.hosts = ['192.168.1.204','192.168.1.205']
#定义目标主机

@runs_once
#当有多台主机时只执行一次
def local_task(): #本地任务函数
    local("hostname")
    print red("hello,world")
    #打印红色字体的结果
def remote_task(): #远程任务函数
    with cd("/usr/local/src"):
       run("ls -lF | grep /$")
#with是python中更优雅的语法，可以很好的处理上下文环境产生的异常,这里用了with以后相当于实现"cd /var/www/html && ls -lsart"的效果。
