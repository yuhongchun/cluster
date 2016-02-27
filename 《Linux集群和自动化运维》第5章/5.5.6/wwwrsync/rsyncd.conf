node 'client.cn7788.com'{
file
{"/etc/crontab":
source => "puppet://server.cn7788.com/modules/pushfile/crontab",
group => root,
owner => root,
mode  => 644,
}
}

node 'fabric.cn7788.com'{
file
{"/etc/hosts":
source => "puppet://server.cn7788.com/modules/pushfile/hosts",
group => root,
owner => root,
mode  => 644,
}
}

node 'nginx.cn7788.com'{
file
{"/etc/resolv.conf":
source => "puppet://server.cn7788.com/modules/pushfile/resolv.conf",
group => root,
owner => root,
mode  => 644,
}
}
