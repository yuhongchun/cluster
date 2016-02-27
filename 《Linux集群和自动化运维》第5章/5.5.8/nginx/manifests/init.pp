class nginx{
        package{"nginx":
        ensure          =>present,
}
        service{"nginx":
        ensure          =>running,
        require         =>Package["nginx"],
}
file{"nginx.conf":
ensure => present,
mode => 644,
owner => root,
group => root,
path => "/etc/nginx/nginx.conf",
content=> template("nginx/nginx.conf.erb"),
require=> Package["nginx"],
}
}
define nginx::vhost($sitedomain,$rootdir) {
    file{ "/etc/nginx/conf.d/${sitedomain}.conf":
        content => template("nginx/nginx_vhost.conf.erb"),
        require => Package["nginx"],
    }
}
