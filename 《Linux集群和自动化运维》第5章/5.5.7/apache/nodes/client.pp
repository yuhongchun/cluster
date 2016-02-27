node 'client.cn7788.com' { 
  include apache 
  apache::vhost {'clientmaster.cn7788.com':
  sitedomain => "webmaster.cn7788.com",
  rootdir => webmaster,
  port => 80, 
}


  apache::vhost {'clienttest.cn7788.com':
  sitedomain => "webtest.cn7788.com",
  rootdir => webtest,
  port => 80, 
}

}
