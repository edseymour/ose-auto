#!/bin/bash

[ "$1" == "" ] && echo "Please provide a configuration file, contents should include:
ident=<path to aws certificate> 
rhnu=<rhn user id>
rhnp=<rhn password>
pool=<subscription pool id>
domain=<EC2 domain>
hosts=\"<host1> <host2> ... <hostn>\"" && exit 1

source "$1"

scmd="ssh -i $ident -o IPQoS=throughput -tt -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=QUIET "

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
   
   $scmd ec2-user@$fqdn "ssh-keygen -b 2048 -f \$HOME/.ssh/id_rsa -q -N '' "

   key=$($scmd ec2-user@$fqdn "cat \$HOME/.ssh/id_rsa.pub" )

   for bnode in $hosts
   do

      bfqdn=$bnode
      [ "${domain}" != "" ] && bfqdn=$bnode.$domain

      $scmd ec2-user@$bfqdn "echo '${key}' >> \$HOME/.ssh/authorized_keys ; chmod 600 \$HOME/.ssh/authorized_keys "

   done

done
