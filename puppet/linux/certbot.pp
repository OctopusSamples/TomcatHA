include apt

package { 'apt-transport-https':
  ensure => installed,
}

package { 'software-properties-common':
  ensure => installed,
}

apt::ppa { 'ppa:certbot/certbot': }
-> package { 'certbot':
  ensure => installed,
}
-> package { 'python-certbot-apache':
  ensure => installed,
}