#!/bin/bash
#
# Filename:
# backupdatabase.sh
# Description:
# backup cms database and remove backup data before 7 days
# crontab
# 55 23 * * * /bin/sh /yundisk/cms/crontab/backupdatabase.sh >> /yundisk/cms/crontab/backupdatabase.log 2>&1

DATE=`date +%Y-%m-%d`
OLDDATE=`date +%Y-%m-%d -d '-7 days'`

#MYSQL=/usr/local/mysql/bin/mysql
#MYSQLDUMP=/usr/local/mysql/bin/mysqldump
#MYSQLADMIN=/usr/local/mysql/bin/mysqladmin

BACKDIR=/yundisk/cms/database
[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
[ -d ${BACKDIR}/${DATE} ] || mkdir ${BACKDIR}/${DATE}
[ ! -d ${BACKDIR}/${OLDDATE} ] || rm -rf ${BACKDIR}/${OLDDATE}

mysqldump --default-character-set=utf8 --no-autocommit --quick --hex-blob --single-transaction -uroot  cms_production  | gzip > ${BACKDIR}/${DATE}/cms-backup-${DATE}.sql.gz
echo "Database cms_production and bbs has been backup successful"
/bin/sleep 5

aws s3 cp ${BACKDIR}/${DATE}/* s3://example-share/cms/databackup/
