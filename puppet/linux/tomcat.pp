package { 'tomcat9':
  ensure => installed,
}
-> package { 'tomcat9-admin':
  ensure => installed,
}
-> augeas {'server.xml':
  incl     =>  '/etc/tomcat9/server.xml',
  context  =>  "/files/etc/tomcat9/server.xml/Server/Service",
  lens     => "Xml.lns",
  changes   => [
    "defnode conn Connector[#attribute/protocol='AJP/1.3']",
    "set $conn/#attribute/port='8009'",
    "set $conn/#attribute/redirectPort='8443'"
  ]
}
-> file_line { 'Change Tomcat Port':
  path    => '/etc/tomcat9/server.xml',
  line    => '    <Connector port="9091" protocol="HTTP/1.1"',
  match   => '^\s*<Connector\ port\="8080"\ protocol\="HTTP/1.1"',
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