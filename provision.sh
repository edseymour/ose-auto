#!/bin/bash

# defaults
AMI=ami-c13591b2
KEYNAME=$USER
SECGROUP=sg-a4bc1ac0
SUBNET=subnet-7d690824

. functions.sh

validate_config count "the number of instances to create"
optional_config AMI "the AWS AMI image id to use, default is $AMI"
optional_config KEYNAME "the AWS keyname used to provision instances, default $KEYNAME"
optional_config SECGROUP "the AWS security group, default $SECGROUP"
optional_config SUBNET "the AWS subnet, default $SUBNET"

# generate an ignore list
ignore=$(aws ec2 describe-instances | grep InstanceId | awk '{print $2}' | cut -d '"' -f2)

echo "*** Provisioning Instances........."
aws ec2 run-instances --image-id $AMI --key-name $KEYNAME \
   --associate-public-ip-address \
   --security-group-ids $SECGROUP --instance-type m4.large \
   --subnet-id $SUBNET --ebs-optimized \
   --block-device-mappings '[ { "DeviceName": "/dev/sdh", "Ebs": { "VolumeSize": 20 }  } ]' \
   --count $count

id=1
tag=$(date +"%Y%d%m-%H%M")
echo "--------------------------

"
echo "INSTANCE NAME,INSTANCE TAG"
# dump out a new list of instances creating using the above start command
aws ec2 describe-instances | grep InstanceId | awk '{print $2}' | cut -d '"' -f2 | while read instanceID
do

   if [[ ${ignore} != *"${instanceID}"* ]]; then

      echo "${instanceID},${tag}"  
      aws ec2 create-tags --resources ${instanceID} --tags Key=Name,Value="inst-${tag}-${id}" Key=RunName,Value="${tag}" > /dev/null
      id=$((id+1))

   fi 

done


