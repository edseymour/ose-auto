#!/bin/bash 

. functions.sh

validate_config_rhn

function subscribe_host 
{
   fqdn=$1

   # subscription manager
   scmd $ssh_user@$fqdn sudo "bash -c \"   subscription-manager unregister ; \
                                       subscription-manager register --username=${rhnu} --password=${rhnp} --force ; \
                                       subscription-manager attach --pool=${pool} ; \
                                       subscription-manager repos --disable=*; \
                                       subscription-manager repos --enable='rhel-7-server-rpms' \
                                                    --enable='rhel-7-server-extras-rpms' \
                                                    --enable='rhel-7-server-optional-rpms' \
                                                    --enable='rhel-7-server-ose-3.1-rpms'; \
                                       yum update -y\"" < /dev/null 
}

[[ ! "$target" == "" ]] && echo "overriding config and configuring for $target" && hosts=$target 

for node in $hosts
do

   fqdn="$node.$domain"

   subscribe_host $fqdn  &

done

wait

