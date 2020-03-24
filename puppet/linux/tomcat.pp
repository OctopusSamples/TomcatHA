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
    "defnode conn Connector[#attribute/protocol='AJP/1.3'] ''",
    "set \$conn/#attribute/port '8009'",
    "set \$conn/#attribute/redirectPort '8443'"
  ]
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