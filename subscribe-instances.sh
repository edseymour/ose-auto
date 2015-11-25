#!/bin/bash 

. functions.sh

validate_config_rhn

for node in $hosts
do

   fqdn="$node.$domain"

   # subscription manager
   scmd $ssh_user@$fqdn sudo "bash -c \"   subscription-manager unregister ; \
                                       subscription-manager register --username=${rhnu} --password=${rhnp} ; \
                                       subscription-manager attach --pool=${pool} ; \
                                       subscription-manager repos --disable=*; \
                                       subscription-manager repos --enable='rhel-7-server-rpms' \
                                                    --enable='rhel-7-server-extras-rpms' \
                                                    --enable='rhel-7-server-optional-rpms' \
                                                    --enable='rhel-7-server-ose-3.1-rpms'; \
                                       yum update -y\"" < /dev/null

done

