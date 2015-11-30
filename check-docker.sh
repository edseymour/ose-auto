#!/bin/bash

. functions.sh

validate_config hosts

for node in $hosts
do

   fqdn=$(gen_fqdn $node)

   scmd $ssh_user@$fqdn sudo docker info | grep -A3 Storage\ Driver


done

