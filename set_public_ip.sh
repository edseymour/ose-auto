#!/bin/bash

. functions.sh

echo "**********************************************
*** Warning, this script guesses the public IPs and hostnames of the hosts
*** using Internet resources. If you are within a corporate firewall
*** do not use, the IP will be set to the edge network NAT"
read -p "press any key"

for node in $hosts
do
   fqdn=$(gen_fqdn $node)
   echo "Updating $fqdn"

   scmd $ssh_user@$fqdn <<-\SSH
PUB_IP=$(curl -s http://myip.dnsomatic.com)
export PUB_IP
PUB_HOST=$PUB_IP

thost=$(host $PUB_IP)
[ $? -eq 0 ] && PUB_HOST=$(echo $thost | awk '{print $5}' | sed 's/\.$//g')
export PUB_HOST

echo "set PUB_IP=$PUB_IP, PUB_HOST=$PUB_HOST"

sudo bash -c "cat <<EOF > /etc/profile.d/pub-info.sh
export PUB_IP=$PUB_IP
export PUB_HOST=$PUB_HOST
EOF"

exit
SSH

done
