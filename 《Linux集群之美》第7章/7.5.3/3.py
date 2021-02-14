#!/usr/bin/python
# -*- coding: utf-8 -*-
from fabric.api import *
from fabric.colors import *
from fabric.context_managers import *
import random
import MySQLdb
import time
# 此脚本主要用于作MHA做两次vip切换时的持续性测试
list_ip = ['172.16.0.8','172.16.0.2']
list_random=random.choice(list_ip)
env.user = 'root'
env.key_filename = '/root/.ssh/id_rsa'
env.roledefs = {
    'master': ['172.16.0.8'],
    'slave' : [list_random],
}

@roles('master')
def restart_master():
    reboot(wait=5)
@roles('slave')
def restart_slave():
    reboot(wait=3)

num = input("请输入要插入数据的值,请保证一定为整数:")

hostvip='172.16.0.9'
user='root'
passwd='123456'
db='test'
port = 3306

start_time = time.time()

conn = MySQLdb.connect(hostvip, user, passwd, db, port)
cur = conn.cursor()
cur.execute("DROP TABLE IF EXISTS test.number")

sql = """CREATE TABLE test.number (
                 id INT NOT NULL,
                 num INT,
                 PRIMARY KEY(id))"""
cur.execute(sql)
conn.commit()

def reConndb():
    _conn_status = True
    _max_retries_count = 30          # 设置最大重试次数
    _conn_retries_count = 0          # 初始重试次数
    _conn_timeout = 3       # 连接超时时间为3秒
    while _conn_status and _conn_retries_count <= _max_retries_count:
                try:
                    conn = MySQLdb.connect(hostvip,user, passwd,db,connect_timeout=_conn_timeout)
                    _conn_status = False  # 如果conn成功则_status为设置为False则退出循环，返回db连接对象
                    return conn
                except:
                    _conn_retries_count += 1
                    print _conn_retries_count
                    print 'connect db is error!!'
                    time.sleep(1)            # 此为测试看效果
                    continue

randomnum1 = random.randrange(100, 1000, 1)
randomnum2 = random.randrange(5000,10000,1)

for x in xrange(num): # 这个时候再插入自定义的数据
    print x
    if x == randomnum1:
        try:
            execute(restart_master)
        except:
	    pass
    if x == randomnum2:
	try:
           execute(restart_slave)
	except:
           pass
    sql = "INSERT INTO number VALUES(%s,%s)" % (x, x)
    conn = reConndb()
    curl = conn.cursor()
    curl.execute(sql)
    conn.commit()

# 打印最后的插入条数
sql = "select count(*) from number;"
conn = MySQLdb.connect(hostvip,user, passwd,db,port)
curl = conn.cursor()
curl.execute(sql)
data = curl.fetchone()
print '最后插入的数据条数为%d:' % data
conn.close()

end_time = time.time()
print '用时：', end_time - start_time