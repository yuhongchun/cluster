#!/bin/bash	
#此脚本应用于开发环境下生成批量用户
for name in tom jerry joe jane yhc brain
do
      useradd $name
      echo redhat | passwd --stdin $name
done
