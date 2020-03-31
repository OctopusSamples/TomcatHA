package { 'augeas-tools':
  ensure => installed
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
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/directive[last()+1] "SSLCertificateChainFile"
    set /files/etc/apache2/sites-enabled/000-default.conf/VirtualHost/*[self::directive="SSLCertificateChainFile"]/arg "/path/to/octopus_tech_bundle.pem"
    print /files/etc/apache2/sites-enabled/000-default.conf
    save
    | EOT
}