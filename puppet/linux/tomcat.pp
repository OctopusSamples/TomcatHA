package { 'tomcat9':
  ensure => installed,
}
-> package { 'tomcat9-admin':
  ensure => installed,
}
-> tomcat::config::server::connector { 'tomcat9-ajp':
  catalina_base         => '/var/lib/tomcat9',
  port                  => '8009',
  protocol              => 'AJP/1.3',
  additional_attributes => {
    'redirectPort' => '8443'
  },
}
-> file_line { 'Define Tomcat worker name':
  path    => '/etc/tomcat9/server.xml',
  line    => '    <Engine defaultHost="localhost" name="Catalina" jvmRoute="worker1">',
  match   => '\s*<Engine name="Catalina" defaultHost="localhost">',
  replace => true,
  notify  => Service['tomcat9']
}
-> file_line { 'Add Tomcat User':
  path    => '/etc/tomcat9/tomcat-users.xml',
  line    => '<role rolename="manager-gui"/><role rolename="manager-script"/><user username="tomcat" password="Password01!" roles="manager-script,manager-gui"/></tomcat-users>',
  match   => '^</tomcat-users>',
  replace => true,
  notify  => Service['tomcat9']
}

service {'tomcat9':
  ensure => running
}