#!/bin/bash

. functions.sh

for node in $hosts
do

   echo $(gen_fqdn $node)

done
