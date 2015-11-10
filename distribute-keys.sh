#!/bin/bash -x

[ "$1" == "" ] && echo "Please provide AWS identity file" && exit 1
[ "$2" == "" ] && echo "Please provide a list of AWS hosts, e.g. \"ec2-55-55-155-155 ec2-55-55-155-156...\"" && exit 1
[ "$3" == "" ] && echo "No domain provided"

ident=$1
domain=$3
hosts=$2

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

   key=$($scmd ec2-user@$fqdn sudo 'bash -c "cat /root/.ssh/id_rsa.pub" ')

   for bnode in $hosts
   do

      bfqdn=$bnode
      [ "${domain}" != "" ] && bfqdn=$bnode.$domain

      $scmd ec2-user@$bfqdn sudo "bash -c 'echo \"${key}\" >> /root/.ssh/authorized_keys'"

   done

done
