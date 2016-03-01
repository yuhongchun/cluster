#!/bin/bash
iptables -I INPUT -p tcp --dport 80 -m state --state NEW -m recent --name web --set 
iptables -A INPUT -m recent --update --name web --seconds 60 --hitcount 20 -j LOG --log-prefix 'HTTP attack: ' 
iptables -A INPUT -m recent --update --name web --seconds 60 --hitcount 20 -j DROP
