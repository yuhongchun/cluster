class wwwrsync{
package { httpd:
ensure => present,
}


file {
"/etc/rsyncd.pass":
source =>"puppet://server.cn7788.com/modules/wwwrsync/rsyncd.pass",
owner =>"root",
group =>"root",
mode =>"600",
}

exec {
"auto rsync web directory":
command =>"rsync -vzrtopg  --delete   test@192.168.1.205::www   /var/www/html  --password-file=/etc/rsyncd.pass",
user =>"root",
path => ["/usr/bin","/usr/sbin","/bin","/bin/sh"],
}
}
