#!/bin/bash 

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

   $scmd ec2-user@$fqdn <<-\SSH

# install pre-requisites
sudo yum install -y wget git net-tools bind-utils iptables-services bridge-utils docker

# configure docker options
sudo sed -i "s/OPTIONS=.*/OPTIONS=\'--selinux-enabled --insecure-registry 172.30.0.0\/16\'/g" /etc/sysconfig/docker 

# enable LVM and wipe existing use of /dev/xvdb
sudo systemctl enable lvm2-lvmetad.service 
sudo systemctl enable lvm2-lvmetad.socket
sudo systemctl start lvm2-lvmetad.service 
sudo systemctl start lvm2-lvmetad.socket

# clean up any existing VG or device allocation
sudo systemctl stop docker
[ $(sudo vgs | grep docker-vg | wc -l) -gt 0 ] && echo "*** removing docker-vg *** " && sudo vgremove docker-vg -y
[ $(sudo pvs | grep /dev/xvdb | wc -l) -gt 0 ] && echo "*** removing xvdb1 pv *** " && sudo pvremove /dev/xvdb1 -y
[ $(sudo fdisk -l | grep xvdb1 | wc -l) -gt 0 ] && echo "*** removing the xvdb1 partition *** " && sudo echo "d
1
w
" | sudo fdisk /dev/xvdb
sudo partprobe
sleep 5

# running docker-storage-setup
sudo bash -c 'cat <<\EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/xvdb
VG=docker-vg
SETUP_LVM_THIN_POOL=yes
EOF'
sudo docker-storage-setup
sudo rm -rf /var/lib/docker/*
sudo systemctl restart docker

#end of script
exit
SSH


done

