import MySQLdb
import time
# -*- coding: UTF-8 -*-
'''
此脚本主要用于交叉测试中DRBD的持续性测试结果，不重启作何一台机器，只关注最后的插入结果
腾讯云的机器CPU较慢，之前测试过10万条数据，会导致整个测试过程很慢，这里配置成50000
'''

num = 50000

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
    _max_retries_count = 30          #设置最大重试次数
    _conn_retries_count = 0          #初始重试次数
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
                    time.sleep(1)            #此为测试看效果
                    continue


for x in xrange(num): # 这个时候再插入自定义的数据
    print x
    sql = "INSERT INTO number VALUES(%s,%s)" % (x, x)
    conn = reConndb()
    curl = conn.cursor()
    try:
        curl.execute(sql)
        conn.commit()
    except:
        conn = reConndb()
        curl = conn.cursor()
        curl.execute(sql)
        conn.commit()


#打印最后的插入条数
sql = "select count(*) from number;"
#conn = MySQLdb.connect(hostvip,user, passwd,db,port)
conn = reConndb()
curl = conn.cursor()
curl.execute(sql)
data = curl.fetchone()
f = open("/tmp/mysql_drbd_new.txt","a")
print >> f, '最后插入的数据条数为%d:' % data
conn.close()

end_time = time.time()
print >> f,'用时：', end_time - start_time