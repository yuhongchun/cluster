#!/usr/bin/env python
#coding:utf-8
#sudo fab -P -z 10 -f /tmp/check_fcdata.py do_task
import time
import sys
import progressbar
from fabric.api import *
from fabric.colors import *
from multiprocessing import Manager
import multiprocessing
env.timeout=10
env.port = '12321'
env.command_timeout=20
env.connection_attempts=2
#env.use_ssh_config=True
env.key_filename="/etc/ssh/identity"
env.disable_known_hosts=True
#这里known_hosts很大就会影响执行速度，所以这里会暂时disable掉

manager=Manager()
plat_list=manager.list()
plat_env=manager.dict()
queue_no=manager.Queue()
queue=manager.Queue(100000)

def flux_check(plat,queue):
    result=[]
    result.append(green("**"*55))
    with settings(hide('running','stdout','warnings','user'), warn_only=True):
        try:
            fcacheCheck_cmd="ls /cache/logs/fcache_data|grep tmp|wc -l"
            fcache_num=run(fcacheCheck_cmd)
            if not fcache_num.succeeded:
                err="[%s] %s: Check fcache_data Fail,Error is:%s !!"%(plat,env.host,fcache_num.stderr)
                result.append(red(err))
            elif int(fcache_num.stdout) > 3:
                err="[%s] %s: fcache_data/*.tmp GT 3 !!"%(plat,env.host)
                result.append(red(err))
            toFtpCheck_cmd="ls /cache/logs/data_to_ftp/|grep tmp|wc -l"
            FtpCheck_num=run(toFtpCheck_cmd)
            if FtpCheck_num.succeeded:
                if int(FtpCheck_num.stdout) > 3:
                    err="[%s] %s: data_to_ftp/*.tmp GT 3 !!"%(plat,env.host)
                    result.append(red(err))
                    print '\n'.join(result)
                    queue.put('aa')
                #return err
                elif len(result)!=1:
                    print '\n'.join(result)
                    queue.put('aa')
            else:
                err="[%s] %s: Check data_to_ftp Fail !!"%(plat,env.host)
                result.append(red(err))
                print '\n'.join(result)
                queue.put('aa')
            #return err
            queue.put('aa')
       except Exception,e:
            queue.put('aa')

def Local_task(platform):
    with settings(hide('everything','running','stdout'), warn_only=True):
        cmd_output = local("/work/squid_conf/control/bin/dev -p %s >%s"%(platform,platform))
        if cmd_output.return_code == 0:
            l=[]
            with open(platform) as f:
                for line in f:
                    l.append(line.strip())
            return l

#@serial
def get_envRole():
    platlist=["c06.i06","c01.i07","c01.i05","c01.i02","c01.i01","c01.p01","c01.p02","s01.p01","s01.p02"]
    for p in platlist:
        ret=execute(Local_task,p)
        plat_env[p]=ret['<local-only>']
    env.roledefs =plat_env
    plat_list.extend(platlist)

def process(Max,queue):
    p = progressbar.ProgressBar(widgets=[
        magenta("[完成进度<-->]"),
        progressbar.Percentage(),
        ' (', progressbar.SimpleProgress(), ') ',
        ' (', progressbar.Bar(), ') ',
        ' (', progressbar.Timer(), ') ',]
    )
    p.maxval=Max
    p.start()
    num=0
    while True:
        if not queue.empty():
            _=queue.get(True)
            num=num+1
            p.update(num)
        if num==Max:
            break
    p.finish()


#@parallel(pool_size=10)
def do_task():
    print
    print green('#'*15)
    print '开始全网校验'
    print green('#'*15)
    Max=0
    for _,v in plat_env.items():
        Max=Max+len(v)
    process_print=multiprocessing.Process(target=process,args=(Max,queue))
    process_print.start()
    for plat in plat_list:
        env.hosts=((env.roledefs)[plat])
        execute(flux_check,plat,queue)

get_envRole()