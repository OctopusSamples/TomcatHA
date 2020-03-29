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