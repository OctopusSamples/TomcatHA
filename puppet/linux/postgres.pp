package { 'postgresql-client':
  ensure => installed,
}
# https://stackoverflow.com/a/18389184/157605
-> file { '/root/initdatabase.sql':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "SELECT 'CREATE DATABASE tomcat' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tomcat')\gexec"
}
-> file { '/root/initschema.sql':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => @(EOT)
    CREATE SCHEMA IF NOT EXISTS session;

    CREATE TABLE IF NOT EXISTS session.sessions (
      session_id     varchar(100) not null primary key,
      valid_session  char(1) not null,
      max_inactive   int not null,
      last_access    bigint not null,
      app_name       varchar(255),
      session_data   mediumblob,
      KEY kapp_name(app_name)
    );
    | EOT
}
-> exec { 'Initialise session database':
  environment => ["PGPASSWORD=$postgres_pass"],
  command   => "/bin/cat /root/initdatabase.sql | /usr/bin/psql -a -U $postgres_user -h $postgres_server",
  logoutput => true
}
-> exec { 'Initialise session table':
  environment => ["PGPASSWORD=$postgres_pass"],
  command   => "/usr/bin/psql -a -d tomcat -U $postgres_user -h $postgres_server -f /root/initschema.sql",
  logoutput => true
}