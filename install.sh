#!/bin/bash

# curl -s -L https://raw.githubusercontent.com/OctopusSamples/TomcatHA/master/install.sh | bash

# https://stackoverflow.com/questions/59895/get-the-source-directory-of-a-bash-script-from-within-the-script-itself
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

wget https://apt.puppetlabs.com/puppet6-release-bionic.deb
sudo dpkg -i puppet6-release-bionic.deb
sudo apt-get update
sudo apt-get install puppet-agent
/opt/puppetlabs/bin/puppet --version

sudo /opt/puppetlabs/bin/puppet module install puppetlabs/apt
sudo /opt/puppetlabs/bin/puppet module install puppetlabs/docker
sudo /opt/puppetlabs/bin/puppet module install puppet/archive
sudo /opt/puppetlabs/bin/puppet module install puppetlabs/inifile
sudo /opt/puppetlabs/bin/puppet module install puppetlabs/tomcat

for var in "$@"
do
    for i in {1..2}
    do
      # sudo -E is required to get the FACTER_ environment variables
      sudo -E /opt/puppetlabs/bin/puppet apply $DIR/puppet/linux/$var --detailed-exitcodes
      if [[ $? -eq 0 ]] || [[ $? -eq 2 ]]
      then
        break
      fi
    done

    if [[ $? -ne 0 ]] && [[ $? -ne 2 ]]
    then
      exit 100
    fi
done

exit 0