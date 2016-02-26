node 'nginx.cn7788.com'{
file
{"/usr/local/src/nagiosins.sh":
source => "puppet://server.cn7788.com/modules/nagiosins/nagiosins.sh",
group => root,
owner => root,
mode  => 755,
}

exec {
"auto install naigios client":
command =>"sh /usr/local/src/nagiosins.sh",
user =>"root",
path => ["/usr/bin","/usr/sbin","/bin","/bin/sh"],
}
}

node 'client.cn7788.com'{
file
{"/usr/local/src/nagiosins.sh":
source => "puppet://server.cn7788.com/modules/nagiosins/nagiosins.sh",
group => root,
owner => root,
mode  => 755,
}

exec {
"auto install naigios client":
command =>"sh /usr/local/src/nagiosins.sh",
user =>"root",
path => ["/usr/bin","/usr/sbin","/bin","/bin/sh"],
}
}


node 'fabric.cn7788.com'{
}
