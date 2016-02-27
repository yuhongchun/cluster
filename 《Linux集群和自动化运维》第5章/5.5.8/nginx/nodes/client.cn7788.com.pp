node 'client.cn7788.com' {
  include nginx
  nginx::vhost {'client.cn7788.com':
  sitedomain => "client.cn7788.com" ,
  rootdir => "client",
}
}
