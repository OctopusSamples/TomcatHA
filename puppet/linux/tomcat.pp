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
  line    => "    <Engine defaultHost=\"localhost\" name=\"Catalina\" jvmRoute=\"$tomcat_name\">",
  match   => '\s*(<Engine defaultHost="localhost" name="Catalina">|<Engine name="Catalina" defaultHost="localhost">)',
  replace => true,
  notify  => Service['tomcat9']
}
-> file_line { 'Add Tomcat User':
  path    => '/etc/tomcat9/tomcat-users.xml',
  line    =>
    '<role rolename="manager-gui"/><role rolename="manager-script"/><user username="tomcat" password="Password01!" roles="manager-script,manager-gui"/></tomcat-users>'
  ,
  match   => '^</tomcat-users>',
  replace => true,
  notify  => Service['tomcat9']
}
-> archive { '/var/lib/tomcat9/lib/postgresql-42.2.11.jar':
  ensure         => present,
  extract        => false,
  source         => 'https://jdbc.postgresql.org/download/postgresql-42.2.11.jar',
  allow_insecure => true
}
-> file_line { 'Configure session replication':
  path     => '/etc/tomcat9/context.xml',
  ensure   => present,
  multiple => false,
  before   => '^</Context>$',
  replace  => true,
  notify   => Service['tomcat9'],
  line     => @("EOT")
    <Manager className="org.apache.catalina.session.PersistentManager" distributable="true"  processExpiresFrequency="3" maxIdleBackup="1" >
        <Store className="org.apache.catalina.session.JDBCStore"
            driverName="org.postgresql.Driver"
            connectionURL="jdbc:postgresql://$postgres_server:5432;ConnectionRetryCount=10;ConnectionRetryDelay=6;DatabaseName=tomcat"
            connectionName="$postgres_user" connectionPassword="$postgres_pass"
            sessionAppCol="app_name" sessionDataCol="session_data" sessionIdCol="session_id"
            sessionLastAccessedCol="last_access" sessionMaxInactiveCol="max_inactive"
            sessionTable="session.tomcat_sessions" sessionValidCol="valid_session" />
    </Manager>
  | EOT
}

service { 'tomcat9':
  ensure => running
}