# coding: UTF-8
import MySQLdb
import time

host='172.16.0.9'
user='root'
passwd='123456'
db='test'
port = 3306

start_time = time.time()
#conn = MySQLdb.connect(host, user, passwd, db, port)
#cur = conn.cursor()

    def reConndb():
    _conn_status = True
    _max_retries_count = 30          #设置最大重试次数
    _conn_retries_count = 0          #初始重试次数
    _conn_timeout = 3       # 连接超时时间为3秒
    while _conn_status and _conn_retries_count <= _max_retries_count:
                try:
                    conn = MySQLdb.connect(host,user, passwd,db,connect_timeout=_conn_timeout)
                    _conn_status = False
# 如果conn成功则_status为设置为False则退出循环，返回db连接对象
                    return conn
                except:
                    _conn_retries_count += 1
                    print _conn_retries_count
                    print 'connect db is error!!'
                    time.sleep(1)            #此为测试看效果
                    continue


for x in xrange(10000):
# 这个时候再插入10000条数据
    print x
    sql = "INSERT INTO number VALUES(%s,%s)" % (x, x)
    conn = reConndb()
    curl = conn.cursor()
    curl.execute(sql)
    conn.commit()

end_time = time.time()
print '用时：', end_time - start_time