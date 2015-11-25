#!/bin/bash

. functions.sh

for node in $hosts
do

   if [ "${domain}" == "" ]
   then
      fqdn=$node
   else
      fqdn="$node.$domain"
   fi

   echo "**************************************************"
   echo "*** Updating $fqdn

"
   
   scmd $ssh_user@$fqdn "ssh-keygen -b 2048 -f \$HOME/.ssh/id_rsa -q -N '' "

   key=$($scmd $ssh_user@$fqdn "cat \$HOME/.ssh/id_rsa.pub" )

   for bnode in $hosts
   do

      bfqdn=$bnode
      [ "${domain}" != "" ] && bfqdn=$bnode.$domain

      scmd $ssh_user@$bfqdn "echo '${key}' >> \$HOME/.ssh/authorized_keys ; chmod 600 \$HOME/.ssh/authorized_keys "

   done

done
