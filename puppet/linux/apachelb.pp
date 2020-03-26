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
  notify  => Service['apache2'],
  content => @(EOT)
    # Define 1 real worker using ajp13
    worker.list=loadbalancer

    # Set properties for worker (ajp13)
    worker.worker1.type=ajp13
    worker.worker1.host=$worker1_ip
    worker.worker1.port=8009

    worker.worker2.type=ajp13
    worker.worker2.host=$worker2_ip
    worker.worker2.port=8009

    # Load-balancing behaviour
    worker.loadbalancer.type=lb
    worker.loadbalancer.balance_workers=worker1,worker2
    worker.loadbalancer.sticky_session=1
    | EOT
}
-> file { '/etc/apache2/sites-enabled/000-default.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  notify  => Service['apache2'],
  content => @(EOT)
    <VirtualHost *:80>
      ErrorLog ${APACHE_LOG_DIR}/error.log
      CustomLog ${APACHE_LOG_DIR}/access.log combined
      JkMount /* loadbalancer
    </VirtualHost>
    | EOT
}

service {'apache2':
  ensure => running
}