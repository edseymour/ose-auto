#!/bin/bash

. functions.sh

validate_config target "please provide hostname of installation server"

scmd $ssh_user@$target "sudo ssh-keygen -b 2048 -f /root/.ssh/id_rsa -q -N '' "

key=$(scmd $ssh_user@$target "sudo cat /root/.ssh/id_rsa.pub")

echo "*** Distributing root key from $target
$key
"

for node in $hosts
do

   fqdn=$(gen_fqdn $node)

   echo "**************************************************"
   echo "*** Updating $fqdn

"
   
   scmd $ssh_user@$fqdn " sudo bash -c 'echo "${key}" >> /root/.ssh/authorized_keys' ; sudo chmod 600 /root/.ssh/authorized_keys "

done
