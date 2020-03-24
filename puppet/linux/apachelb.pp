package { 'apache2':
  ensure => installed
}
-> package { 'libapache2-mod-jk':
  ensure => installed
}
-> file { '/etc/libapache2-mod-jk/workers.properties':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => @(EOT)
    # Define 1 real worker using ajp13
    worker.list=worker1
    # Set properties for worker (ajp13)
    worker.worker1.type=ajp13
    worker.worker1.host=localhost
    worker.worker1.port=8009
    | EOT
}
-> file { '/etc/apache2/sites-enabled/000-default.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => @(EOT)
    Listen 80
    <VirtualHost *:80>
      ErrorLog ${APACHE_LOG_DIR}/error.log
      CustomLog ${APACHE_LOG_DIR}/access.log combined
      JkMount /* worker1
    </VirtualHost>
    | EOT
}