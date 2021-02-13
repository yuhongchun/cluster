#!/bin/sh
SVNDIR=/data/svn
SVNADMIN=/usr/bin/svnadmin
DATE=`date +%Y-%m-%d`
OLDDATE=`date +%Y-%m-%d -d '30 days'`
BACKDIR=/data/backup/svn-backup

[ -d ${BACKDIR} ] || mkdir -p ${BACKDIR}
LogFile=${BACKDIR}/svnbak.log
[ -f ${LogFile} ] || touch ${LogFile}
mkdir ${BACKDIR}/${DATE}


for PROJECT in myproject official analysis mypharma
do
  cd $SVNDIR
  $SVNADMIN hotcopy $PROJECT  $BACKDIR/$DATE/$PROJECT --clean-logs
  cd $BACKDIR/$DATE
  tar zcvf ${PROJECT}_svn_${DATE}.tar.gz $PROJECT  > /dev/null
  rm -rf $PROJECT
sleep 2
done

HOST=192.168.2.112
FTP_USERNAME=svn
FTP_PASSWORD=svn101

cd ${BACKDIR}/${DATE}

ftp -i -n -v << !
open ${HOST}
user ${FTP_USERNAME} ${FTP_PASSWORD}
bin
cd ${OLDDATE}
mdelete *
cd ..
rmdir ${OLDDATE}
mkdir ${DATE}
cd ${DATE}
mput *
bye
!
