#!/bin/bash 

[ "$1" == "" ] && echo "Please provide a configuration file, contents should include:
ident=<path to aws certificate> 
rhnu=<rhn user id>
rhnp=<rhn password>
pool=<subscription pool id>
domain=<EC2 domain>
hosts=\"<host1> <host2> ... <hostn>\"" && exit 1

source "$1"

scmd="ssh -i $ident -o IPQoS=throughput -tt -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=QUIET"

for node in $hosts
do

   fqdn="$node.$domain"

   # subscription manager
   $scmd ec2-user@$fqdn sudo "bash -c \"ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ''; \
                                        subscription-manager register --username=${rhnu} --password=${rhnp} ; \
                                        subscription-manager attach --pool=${pool} ; \
                                        subscription-manager repos --disable=*; \
                                        subscription-manager repos --enable='rhel-7-server-rpms' \
                                                    --enable='rhel-7-server-extras-rpms' \
                                                    --enable='rhel-7-server-optional-rpms' \
                                                    --enable='rhel-7-server-ose-3.1-rpms'; \
                                        yum update -y\"" < /dev/null

done

