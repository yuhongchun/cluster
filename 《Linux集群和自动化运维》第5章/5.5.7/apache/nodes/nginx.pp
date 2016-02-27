node 'nginx.cn7788.com' { 
  include apache 
  apache::vhost {'webmaster.cn7788.com':
  sitedomain => "webmaster.cn7788.com",
  rootdir => webmaster,
  port => 80, 
}


  apache::vhost {'webtest.cn7788.com':
  sitedomain => "webtest.cn7788.com",
  rootdir => webtest,
  port => 80, 
}


apache::vhost {'webrsync.cn7788.com':
  sitedomain => "webrsync.cn7788.com",
  rootdir => webrsync,
  port => 80, 
}
}
