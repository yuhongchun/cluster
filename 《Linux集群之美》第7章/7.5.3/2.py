#!/usr/bin/python
# -*- coding: UTF-8 -*-
import MySQLdb
import time

host='172.16.0.9'
user='root'
passwd='123456'
db='test'
port = 3306

def reConndb():
    _conn_status = True
    _max_retries_count = 30          #设置最大重试次数
    _conn_retries_count = 0          #初始重试次数
    _conn_timeout = 3       # 连接超时时间为3秒
    while _conn_status and _conn_retries_count <= _max_retries_count:
        try:
            conn = MySQLdb.connect(host,user, passwd,db,connect_timeout=_conn_timeout)
            _conn_status = False  # 如果conn成功则_status为设置为False则退出循环，返回db连接对象
            return conn
        except:
            _conn_retries_count += 1
            print _conn_retries_count
            print 'connect db is error!!'
            time.sleep(1)            #此为测试看效果
            continue

conn = reConndb()
curl = conn.cursor()
# 如果数据表已经存在使用 execute() 方法删除表。
curl.execute("DROP TABLE IF EXISTS EMPLOYEE")

# 创建数据表SQL语句
sql = """CREATE TABLE EMPLOYEE (
         FIRST_NAME  CHAR(20) NOT NULL,
         LAST_NAME  CHAR(20),
         AGE INT,  
         SEX CHAR(1),
         INCOME FLOAT )"""
curl.execute(sql)

# SQL 插入语句
sql1 = """INSERT INTO EMPLOYEE(FIRST_NAME,
         LAST_NAME, AGE, SEX, INCOME)
         VALUES ('Mac', 'Mohan', 20, 'M', 2000)"""
sql2 = """DELETE FROM sbtest1"""
# 执行sql语句
curl.execute(sql1)
curl.execute(sql2)
# 提交到数据库执行
conn.commit()
# 关闭数据库连接
conn.close()
