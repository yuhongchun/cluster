class apache{
        package{"httpd":
        ensure          =>present,
}
        service{"httpd":
        ensure          =>running,
        require         =>Package["httpd"],
}
}

define apache::vhost ( $sitedomain, $rootdir,$port ) {
    file { "/etc/httpd/conf.d/httpd_vhost_${sitedomain}.conf":
         #path    => '/etc/httpd/conf/httpd_vhost.conf',
         content => template("apache/httpd.conf.erb"),
         require => Package["httpd"],
    }
}
