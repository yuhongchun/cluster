node 'nginx.cn7788.com' {
  include nginx
  nginx::vhost {'nginx.cn7788.com':
  sitedomain => "nginx.cn7788.com" ,
  rootdir => "nginx",
}
}
