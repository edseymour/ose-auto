#!/bin/bash


IMAGES=(
rhscl/devtoolset-4-toolchain-rhel7 
rhscl/httpd-24-rhel7               
rhscl/mariadb-100-rhel7            
rhscl/mongodb-26-rhel7             
rhscl/mysql-56-rhel7               
rhscl/nginx-16-rhel7               
rhscl/passenger-40-rhel7           
rhscl/perl-520-rhel7               
rhscl/php-56-rhel7                 
rhscl/postgresql-94-rhel7          
rhscl/python-27-rhel7              
rhscl/python-34-rhel7              
rhscl/ror-41-rhel7                 
rhscl/ruby-22-rhel7                
rhscl/s2i-base-rhel7               
)

for image in "${IMAGES[@]}"; do

  tags=$(curl -s https://registry.access.redhat.com/v1/repositories/$image/tags | python -c "import json
import random
import string
import sys

def key_val(pairs, key):
    for k in pairs:
       if k["Key"] == key:
          return k["Value"]
    return None

j = json.loads(sys.stdin.read())
for r in j:
   print r
")

  for tag in $tags; do

     if [[ "$tag" == *"-"* ]] ; then
        echo "skipping $image:$tag"
     else
        echo "prefetching $image:$tag"
        docker pull registry.access.redhat.com/$image:$tag
     fi
  done

done



