$apache_server = $::operatingsystem ? {
  'Ubuntu'  => 'apache2',
  default => 'httpd',
}

package { 'augeas-tools':
  ensure => installed
}

package { $apache_server:
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
  content => @("EOT")
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

file { '/opt/augapache':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => @(EOT)
    #!/usr/bin/augtool -Af
    set /augeas/load/Httpd/lens Httpd.lns
    set /augeas/load/Httpd/incl /etc/apache2/sites-enabled/000-default.conf
    load
    print /files/etc/apache2/sites-enabled/000-default.conf
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/arg "*:443"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/directive[last()+1] "SSLEngine"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/*[self::directive="SSLEngine"]/arg "on"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/directive[last()+1] "SSLCertificateFile"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/*[self::directive="SSLCertificateFile"]/arg "/path/to/octopus_tech.crt"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/directive[last()+1] "SSLCertificateKeyFile"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/*[self::directive="SSLCertificateKeyFile"]/arg "/path/to/octopus_tech.key"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/directive[last()+1] "SSLCertificateKeyFile"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/*[self::directive="SSLCertificateChainFile"]/arg "/path/to/octopus_tech_bundle.pem"
    print /files/etc/apache2/sites-enabled/000-default.conf
    save
    | EOT
}

service {'apache2':
  ensure => running
}