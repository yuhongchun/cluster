#!/bin/bash
USERNAME=mysqlbackup
PASSWORD=mysqlbackup
DATE=`date +%Y-%m-%d`
OLDDATE=`date +%Y-%m-%d -d '-20 days'`
FTPOLDDATE=`date +%Y-%m-%d -d '-60 days'`
MYSQL=/usr/local/mysql/bin/mysql
MYSQLDUMP=/usr/local/mysql/bin/mysqldump
MYSQLADMIN=/usr/local/mysql/bin/mysqladmin
SOCKET=/tmp/mysql.sock
BACKDIR=/data/backup/db

[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
[ -d ${BACKDIR}/${DATE} ] || mkdir ${BACKDIR}/${DATE}
[ ! -d ${BACKDIR}/${OLDDATE} ] || rm -rf ${BACKDIR}/${OLDDATE}

for DBNAME in mysql test report
do
   ${MYSQLDUMP} --opt -u${USERNAME} -p${PASSWORD} -S${SOCKET} ${DBNAME} | gzip > ${BACKDIR}/${DATE}/${DBNAME}-backup-${DATE}.sql.gz
   echo "${DBNAME} has been backup successful"
   /bin/sleep 5
done

HOST=192.168.4.45
FTP_USERNAME=dbmysql
FTP_PASSWORD=dbmysql
cd ${BACKDIR}/${DATE}
ftp -i -n -v << !
open ${HOST}
user ${FTP_USERNAME} ${FTP_PASSWORD}
bin
cd ${FTPOLDDATE}
mdelete *
cd ..
rmdir ${FTPOLDDATE}
mkdir ${DATE}
cd ${DATE}
mput *
bye
!
