include apt

# Get the key with:
# gpg --show-keys public.key
# https://security.stackexchange.com/a/199892
apt::key { 'octopus-repository':
  id     => 'DF4235AA125D66D3938B0377896C79DABCE1F8D1',
  source => 'https://apt.octopus.com/public.key',
  server  => 'pgp.mit.edu'
}
-> apt::source { 'octopus':
  comment  => 'This is the Octopus repository',
  location => 'https://apt.octopus.com/',
  release  => '',
  repos    => 'stretch main',
  key      => {
    'id' => 'DF4235AA125D66D3938B0377896C79DABCE1F8D1',
  },
  include  => {
    'deb' => true,
  },
}
-> package { 'tentacle':
  ensure => installed,
}
# -> file { '/root/addtentacle.sh':
#   ensure  => 'file',
#   owner   => 'root',
#   group   => 'root',
#   mode    => '0755',
#   content => @("EOT")
#     sudo /opt/octopus/tentacle/Tentacle create-instance --instance "Tentacle" --config "/etc/octopus/Tentacle/tentacle-Tentacle.config"
#     sudo /opt/octopus/tentacle/Tentacle new-certificate --instance "Tentacle" --if-blank
#     sudo /opt/octopus/tentacle/Tentacle configure --instance "Tentacle" --app "/home/Octopus/Applications" --noListen "True" --reset-trust
#     sudo /opt/octopus/tentacle/Tentacle register-with --instance "Tentacle" --server "$octopus_server" --name "$tomcat_name" --comms-style "TentacleActive" --server-comms-port "10943" --apiKey "$octopus_api_key" --space "$octopus_space" --environment "$octopus_environment"  --role "tomcat"
#     sudo /opt/octopus/tentacle/Tentacle service --install --start --instance "Tentacle"
#     | EOT
# }
# -> exec { 'Add Tentacle':
#   command   => "/root/addtentacle.sh",
#   logoutput => true
# }