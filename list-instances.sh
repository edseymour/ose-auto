#!/bin/bash

filter=$1
[ "${filter}" == "" ] && echo "** Please provide RunName tag value **" && exit 1

aws ec2 describe-instances --filters "Name=tag:RunName,Values=${filter}" | python print-instances.py 



