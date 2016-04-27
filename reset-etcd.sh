#!/bin/bash 


. functions.sh

validate_config etcds

for h in $etcds
do

   scmd $ssh_user@$h sudo systemctl stop etcd

done

for h in $etcds
do

   scmd $ssh_user@$h sudo rm -rf /var/lib/etcd/*

done

for h in $etcds
do

   scmd $ssh_user@$h sudo systemctl start etcd

done


for h in $etcds
do

   scmd $ssh_user@$h sudo journalctl -n 20 -u etcd

done
