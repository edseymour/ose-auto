#!/bin/bash 

. functions.sh

validate_config dev

OSE_DEVICE=$dev

echo "********** WARNING ****************"
echo "*** This script could delete data irrevocably"
echo "*** For each host listed here: $hosts"
echo "*** The script will permanently wipe all data from /dev/$OSE_DEVICE"
echo "*** Only proceed if you are absolutely sure that's what you want to do, CTRL-C to exit now"
read -p "Press any key to continue"

for node in $hosts
do

   if [ "${domain}" == "" ]
   then
      fqdn=$node
   else
      fqdn="$node.$domain"
   fi

   echo "************************************************************************************"
   echo "*** Updating $fqdn, using /dev/$OSE_DEVICE for docker storage

"
   # export the OSE_DEVICE variable
   scmd $ssh_user@$fqdn sudo "bash -c 'echo \"OSE_DEVICE=${OSE_DEVICE};  export OSE_DEVICE\" > /etc/profile.d/ose-device.sh'" 

   scmd $ssh_user@$fqdn <<-\SSH

# install pre-requisites
sudo yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion atomic-openshift-utils docker

# configure docker options
sudo sed -i "s/OPTIONS=.*/OPTIONS=\'--selinux-enabled --insecure-registry 172.30.0.0\/16\'/g" /etc/sysconfig/docker 

# enable LVM and wipe existing use of /dev/<device>
sudo systemctl enable lvm2-lvmetad.service 
sudo systemctl enable lvm2-lvmetad.socket
sudo systemctl restart lvm2-lvmetad.service 
sudo systemctl restart lvm2-lvmetad.socket

# clean up any existing VG or device allocation
sudo systemctl stop docker
[ $(sudo vgs | grep docker-vg | wc -l) -gt 0 ] && echo "*** removing docker-vg *** " && sudo vgremove docker-vg -y
[ $(sudo pvs | grep /dev/${OSE_DEVICE} | wc -l) -gt 0 ] && echo "*** removing ${OSE_DEVICE}1 pv *** " && sudo pvremove /dev/${OSE_DEVICE}1 -y
[ $(sudo fdisk -l | grep ${OSE_DEVICE}1 | wc -l) -gt 0 ] && echo "*** removing the ${OSE_DEVICE}1 partition *** " && sudo echo "d
1
w
" | sudo fdisk /dev/${OSE_DEVICE}
sudo partprobe
sleep 2

# running docker-storage-setup
sudo bash -c "cat <<\EOF > /etc/sysconfig/docker-storage-setup
DEVS=/dev/${OSE_DEVICE}
VG=docker-vg
EOF"
sudo bash -c 'yes | docker-storage-setup'
sudo rm -rf /var/lib/docker/*
sudo systemctl restart docker

#end of script
exit
SSH


done

