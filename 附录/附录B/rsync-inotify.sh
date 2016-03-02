#!/bin/bash
src=/data/html/www/images/
des_ip1=192.168.1.204
des_ip2=192.168.1.205

/usr/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format  '%T %w%f' -e modify,delete,create,attrib $src | while read  file
   do
      rsync -vzrtopg --delete --progress $src www@$des_ip1::web1_sync --password-file=/etc/rsyncd.password
      rsync -vzrtopg --delete --progress $src www@$des_ip2::web2_sync --password-file=/etc/rsyncd.password
      echo "$src was rsynced"
   done