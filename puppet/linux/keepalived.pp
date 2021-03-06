package { 'keepalived':
  ensure => installed
}
-> package { 'awscli':
  ensure => installed
}
-> package { 'python':
  ensure => installed
}
-> file { '/usr/lib/keepalived':
  ensure => 'directory'
}
# https://github.com/nginxinc/aws-ha-elastic-ip
-> file { '/usr/lib/keepalived/ha-notify':
  ensure  => 'file',
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  notify  => Service['keepalived'],
  content => @("EOT"/$)
#!/bin/bash

#############--USER DEFINED VARIABLES SET HERE--##############
#Set the AWS credentials here if you didn't create an IAM instance profile
#export AWS_ACCESS_KEY_ID=
#export AWS_SECRET_ACCESS_KEY=

#Set the AWS default region
export AWS_DEFAULT_REGION=us-east-1

#Set the internal or private DNS names of the HA nodes here
HA_NODE_1=$lb1_dns
HA_NODE_2=$lb2_dns

#Set the ElasticIP ID Value here
ALLOCATION_ID=$eip_allocation
###############################################################

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

#Values passed in from keepalived
TYPE=\$1
NAME=\$2
STATE=\$3

#Determine the internal or private dns name of the instance
LOCAL_INTERNAL_DNS_NAME=`wget -q -O - http://instance-data/latest/meta-data/local-hostname`
LOCAL_INTERNAL_DNS_NAME=`echo \$LOCAL_INTERNAL_DNS_NAME | sed -e 's/% //g'`

#OTHER_INSTANCE_DNS_NAME is the other node than this one, default assignment is HA_NODE_1
OTHER_INSTANCE_DNS_NAME=\$HA_NODE_1

#Use LOCAL_INTERNAL_DNS_NAME to determine which node this is and to set the Other Node name
if [ "\$HA_NODE_1" = "\$LOCAL_INTERNAL_DNS_NAME" ]
then
    OTHER_INSTANCE_DNS_NAME=\$HA_NODE_2
fi

#Get the local instance ID
INSTANCE_ID=`wget -q -O - http://instance-data/latest/meta-data/instance-id`
INSTANCE_ID=`echo \$INSTANCE_ID | sed -e 's/% //g'`

#Get the instance ID of the other node
OTHER_INSTANCE_ID=`aws ec2 describe-instances --filter "Name=private-dns-name,Values=\$OTHER_INSTANCE_DNS_NAME" | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Reservations"][0]["Instances"][0]["InstanceId"]'`

#Get the ASSOCIATION_ID of the ElasticIP to the Instance
ASSOCIATION_ID=`aws ec2 describe-addresses --allocation-id \$ALLOCATION_ID | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Addresses"][0]["AssociationId"]'`

#Get the INSTANCE_ID of the system the ElasticIP is associated with
EIP_INSTANCE=`aws ec2 describe-addresses --allocation-id \$ALLOCATION_ID | /usr/bin/python -c 'import json,sys;obj=json.load(sys.stdin); print obj["Addresses"][0]["InstanceId"]'`

STATEFILE=/var/run/ha-keepalived.state

logger -t ha-keepalived "Params and Values: TYPE=\$TYPE -- NAME=\$NAME -- STATE=\$STATE -- ALLOCATION_ID=\$ALLOCATION_ID -- INSTANCE_ID=\$INSTANCE_ID -- OTHER_INSTANCE_ID=\$OTHER_INSTANCE_ID -- EIP_INSTANCE=\$EIP_INSTANCE -- ASSOCIATION_ID=\$ASSOCIATION_ID -- STATEFILE=\$STATEFILE"

logger -t ha-keepalived "Transition to state '\$STATE' on VRRP instance '\$NAME'."

case \$STATE in
        "MASTER")
                  aws ec2 disassociate-address --association-id \$ASSOCIATION_ID
                  aws ec2 associate-address --allocation-id \$ALLOCATION_ID --instance-id \$INSTANCE_ID
                  echo "STATE=\$STATE" > \$STATEFILE
                  exit 0
                  ;;
        "BACKUP"|"FAULT")
                  if [ "\$INSTANCE_ID" = "\$EIP_INSTANCE" ]
                  then
                    aws ec2 disassociate-address --association-id \$ASSOCIATION_ID
                    aws ec2 associate-address --allocation-id \$ALLOCATION_ID --instance-id \$OTHER_INSTANCE_ID
                    logger -t ha-keepalived "BACKUP Path Transfer from \$INSTANCE_ID to \$OTHER_INSTANCE_ID"
                  fi
                  echo "STATE=\$STATE" > \$STATEFILE
                  exit 0
                  ;;
        *)        logger -t ha-keepalived "Unknown state: '\$STATE'"
                  exit 1
                  ;;
esac
    | EOT
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
        unicast_src_ip $loadbalancer_ip
        unicast_peer {
          $other_loadbalancer_ip
        }

        # On-premises, this IP can float within a subnet. On AWS this IP address is not routable without modifying VPC route tables.
        virtual_ipaddress {
            10.0.0.30
        }

        # On AWS this script reassigns an elastic IP. See https://docs.nginx.com/nginx/deployment-guides/amazon-web-services/high-availability-keepalived/
        notify /usr/lib/keepalived/ha-notify
    }
    | EOT
}

service {'keepalived':
  ensure => running
}