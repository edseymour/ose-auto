#!/bin/bash 

. functions.sh

validate_config_rhn

function subscribe_host 
{
   fqdn=$1

   # subscription manager
   scmd $ssh_user@$fqdn sudo "bash -c 'subscription-manager unregister'" < /dev/null 
}

for node in $hosts
do

   fqdn="$node.$domain"

   subscribe_host $fqdn &

done

wait

