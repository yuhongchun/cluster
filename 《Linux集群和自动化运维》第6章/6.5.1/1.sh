#/bin/bash
iptables -F
iptables -F -t nat
iptables -X
iptables -Z
iptables -P INPUT DROP
iptables -A INPUT -m state --state NEW -j DROP
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
