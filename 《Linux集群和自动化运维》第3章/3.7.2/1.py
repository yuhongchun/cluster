#!/usr/bin/python2.6
# -*- coding: utf-8 -*-
from fabric.api import *
from fabric.colors import * 
from fabric.context_managers import *
#这里为了简化工作，脚本采用纯python的写法，没有采用Fabric的@task修饰器

env.user = 'ec2-user'
env.key_filename = '/home/ec2-user/.ssh/id_rsa'
hosts=['budget','adserver','bidder1','bidder2','bidder3','bidder4','bidder5','bidder6','bidder7','bidder8','bidder9',redis1','redis2','redis3','redis4','redis5','redis6']
#机器数量多，这里只是罗列部分，

def put_ec2_key():
    with settings(warn_only=False):
        put("/home/ec2-user/admin-master.pub","/home/ec2-user/admin-master.pub")
        sudo("\cp /home/ec2-user/admin-master.pub /home/ec2-user/.ssh/authorized_keys")
        sudo("chmod 600 /home/ec2-user/.ssh/authorized_keys")

def put_admin_key():
    with settings(warn_only=False):
       put("/home/ec2-user/admin-operation.pub",
"/home/ec2-user/admin-operation.pub")
       sudo("\cp /home/ec2-user/admin-operation.pub  /home/admin/.ssh/authorized_keys")
       sudo("chown admin:admin /home/admin/.ssh/authorized_keys")
       sudo("chmod 600 /home/admin/.ssh/authorized_keys")

def put_readonly_key():
      with settings(warn_only=False):
      put("/home/ec2-user/admin-readonly.pub",
"/home/ec2-user/admin-readonly.pub")
      sudo("\cp /home/ec2-user/admin-readonly.pub /home/readonly/.ssh/authorized_keys")
      sudo("chown readonly:readonly /home/readonly/.ssh/authorized_keys")
      sudo("chmod 600 /home/readonly/.ssh/authorized_keys")

for host in hosts:
    env.host_string = host
    put_ec2_key()
    put_admin_key()
    put_readonly_key()
