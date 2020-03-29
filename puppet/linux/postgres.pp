package { 'postgresql-client':
  ensure => installed,
}
# Creating an initial database is not quite as easy as it apears
# https://stackoverflow.com/a/18389184/157605
-> file { '/root/initdatabase.sql':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => "SELECT 'CREATE DATABASE tomcat' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'tomcat')\\gexec"
}
-> file { '/root/initschema.sql':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => @(EOT)
    CREATE SCHEMA IF NOT EXISTS session;

    CREATE TABLE session.tomcat_sessions
    (
      session_id character varying(100) NOT NULL,
      valid_session character(1) NOT NULL,
      max_inactive integer NOT NULL,
      last_access bigint NOT NULL,
      app_name character varying(255),
      session_data bytea,
      CONSTRAINT tomcat_sessions_pkey PRIMARY KEY (session_id)
    );

    CREATE INDEX app_name_index
      ON session.tomcat_sessions
      USING btree
      (app_name);
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