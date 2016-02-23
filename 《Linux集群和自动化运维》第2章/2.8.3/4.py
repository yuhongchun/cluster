#!/bin/bash
sync_redis_status=`ps aux | grep sync_redis.py | grep -v grep | wc -l `
if [ ${sync_redis_status} != 1 ]; then
    echo "Critical! sync_redis is Died"
    exit 2
else
    echo "OK! sync_redis is Alive"
    exit 0
fi
