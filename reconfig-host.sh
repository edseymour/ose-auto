#!/bin/bash

# used for reconfiguring system if the public hostname has changed (AWS restart an instance)

. functions.sh

validate_config old_host
validate_config new_host
optional_config old_ip "Original IP address" 
optional_config new_ip "New IP address, if not present will guess based on new_host"

scmd $ssh_user@$new_host "sudo find /etc -type f -exec sed -i 's/$old_host/$new_host/g' {} \; 

if [[ ! "$old_ip" == "" ]] ; then

   if [[ "$new_ip" == "" ]]; then
      # new_ip isn't set so we will guess, first trying public IP, if this fails, then private IP. Better to pass the value in!
      new_ip=$(curl -s http://myip.dnsomatic.com)
      [ $? -ne 0 ] && new_ip=$(host $new_host | awk '{print $4}') ; # likely to set to private IP address
   fi

   sudo find /etc -type f -exec sed -i 's/$old_ip/$new_ip/g' {} \;
fi

sudo systemctl restart atomic-openshift-master 
sudo systemctl restart atomic-openshift-node
sudo systemctl status atomic-openshift-master  
sudo systemctl status atomic-openshift-node
sudo oc get nodes
sudo oc get pods -n default"



