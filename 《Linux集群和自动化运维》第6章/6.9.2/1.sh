#/bin/bash
netstat -an| grep :25 | grep -v 127.0.0.1 |awk '{ print $5 }' | sort|awk -F: '{print $1,$4}' | uniq -c | awk '$1 >50 {print $1,$2}' > /root/black.txt

for i in `awk '{print $2}' /root/black.txt`
do
COUNT=`grep $i /root/black.txt | awk '{print \$1}'`
DEFINE="1000"
ZERO="0"
if [ $COUNT -gt $DEFINE ];
	then
	grep $i /root/white.txt > /dev/null
	if [ $? -gt $ZERO ];
    	then
     	echo "$COUNT $i"
     	iptables -I INPUT -p tcp -s $i -j DROP
    fi
fi
done
