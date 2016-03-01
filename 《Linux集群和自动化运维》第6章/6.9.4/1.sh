#!/bin/bash
cd /usr/local/src
wget http://jaist.dl.sourceforge.net/sourceforge/denyhosts/DenyHosts-2.6.tar.gz
tar zxf DenyHosts-2.6.tar.gz
cd DenyHosts-2.6
python setup.py install
cd /usr/share/denyhosts/
cp daemon-control-dist daemon-control
chown root daemon-control
chmod 700 daemon-control
grep -v "^#" denyhosts.cfg-dist > denyhosts.cfg
echo "/usr/share/denyhosts/daemon-control start" >>/etc/rc.local
cd /etc/init.d
ln -s /usr/share/denyhosts/daemon-control denyhosts
chkconfig --add denyhosts
chkconfig --level 345 denyhosts on
service denyhosts start
