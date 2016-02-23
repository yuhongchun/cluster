#!/usr/bin/python
#Check redis Nagios Plungin,Please install the redis-py module.
import redis
import sys 

STATUS_OK = 0
STATUS_WARNING = 1
STATUS_CRITICAL = 2

HOST = sys.argv[1]
PORT = int(sys.argv[2])
WARNING = float(sys.argv[3])
CRITICAL = float(sys.argv[4])

def connect_redis(host, port):
    r = redis.Redis(host, port, socket_timeout = 5, socket_connect_timeout = 5)
    return r

def main():
    r = connect_redis(HOST, PORT)
    try:
        r.ping()
    except:
        print HOST,PORT,'down'
        sys.exit(STATUS_CRITICAL)

    redis_info = r.info()
    used_mem = redis_info['used_memory']/1024/1024/1024.0
    used_mem_human = redis_info['used_memory_human']

    if WARNING <= used_mem < CRITICAL:
        print HOST,PORT,'use memory warning',used_mem_human
        sys.exit(STATUS_WARNING)
    elif used_mem >= CRITICAL:
        print HOST,PORT,'use memory critical',used_mem_human
        sys.exit(STATUS_CRITICAL)
    else:
        print HOST,PORT,'use memory ok',used_mem_human
        sys.exit(STATUS_OK)

if __name__ == '__main__':
    main()
