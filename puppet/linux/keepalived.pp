package { 'keepalived':
  ensure => installed
}
-> file { '/etc/keepalived/keepalived.conf':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  notify  => Service['keepalived'],
  content => @("EOT")
    vrrp_instance $loadbalancer_name {
        state MASTER
        interface ens5
        virtual_router_id 101
        priority $loadbalancer_priority
        advert_int 1
        authentication {
            auth_type PASS
            auth_pass $keepalive_pass
        }
        virtual_ipaddress {
            10.0.0.30
        }
        unicast_src_ip $loadbalancer_ip
        unicast_peer {
          $other_loadbalancer_ip
        }
    }
    | EOT
}

service {'keepalived':
  ensure => running
}