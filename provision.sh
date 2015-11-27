#!/bin/bash

N=$1
[ "$N" == "" ] || [ "$N" -le "0" ] && echo "*** PLEASE PROVIDE THE NUMBER OF INSTANCES TO CREATE ***" && exit 1

AMI=ami-2d3c985e
KEYNAME=$USER
SECGROUP=sg-a4bc1ac0
SUBNET=subnet-7d690824

# generate an ignore list
ignore=$(aws ec2 describe-instances | grep InstanceId | awk '{print $2}' | cut -d '"' -f2)

 aws ec2 run-instances --image-id $AMI --key-name $KEYNAME \
   --associate-public-ip-address \
   --security-group-ids $SECGROUP --instance-type m4.large \
   --subnet-id $SUBNET --ebs-optimized \
   --count $N

