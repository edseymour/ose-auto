#!/bin/bash

# used for reconfiguring system if the public hostname has changed (AWS restart an instance)

. functions.sh

validate_config old_host
validate_config new_host

scmd $ssh_user@$new_host "sudo find /etc -type f -exec sed -i 's/$old_host/$new_host/g' {} \; 
sudo systemctl restart atomic-openshift-master 
sudo systemctl restart atomic-openshift-node
sudo systemctl status atomic-openshift-master  
sudo systemctl status atomic-openshift-node
sudo oc get nodes
sudo oc get pods -n default"



