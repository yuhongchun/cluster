#/bin/bash
#Date:2012/09/27

DB=pharma
USER=root
PASSWD=root@change


/usr/local/mysql/bin/mysql  -u$USER -p$PASSWD $DB -e "select TABLE_NAME from information_schema.TABLES where TABLE_SCHEMA='"$DB"' and ENGINE='"MyISAM"';" | grep -v "TABLE_NAME" > mysql_table.txt
#for t_name in `cat tables.txt`


cat  mysql_table.txt | while read LINE
do
    echo "Starting convert table engine..."
    /usr/local/mysql/bin/mysql -u$USER -p$PASSWD $DB -e "alter table $LINE  engine='"InnoDB"'"
    sleep 1
done
