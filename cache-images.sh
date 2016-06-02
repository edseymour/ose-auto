#!/bin/bash 

RH_REPO=registry.access.redhat.com
RH_IMAGES=(openshift3/ose-haproxy-router
 openshift3/ose-deployer
 openshift3/ose-sti-builder
 openshift3/ose-docker-builder
 openshift3/ose-pod
 openshift3/ose-docker-registry
 openshift3/logging-deployment
 openshift3/logging-elasticsearch
 openshift3/logging-kibana
 openshift3/logging-fluentd
 openshift3/logging-auth-proxy
 openshift3/metrics-deployer
 openshift3/metrics-hawkular-metrics
 openshift3/metrics-cassandra
 openshift3/metrics-heapster
 jboss-amq-6/amq62-openshift
 jboss-eap-6/eap64-openshift
 jboss-webserver-3/webserver30-tomcat7-openshift
 jboss-webserver-3/webserver30-tomcat8-openshift
 rhscl/mongodb-26-rhel7
 rhscl/mysql-56-rhel7
 rhscl/perl-520-rhel7
 rhscl/php-56-rhel7
 rhscl/postgresql-94-rhel7
 rhscl/python-27-rhel7
 rhscl/python-34-rhel7
 rhscl/ruby-22-rhel7
 openshift3/nodejs-010-rhel7
)

function repo_url
{
   case $1 in
      registry.access.redhat.com)
      echo "https://registry.access.redhat.com/v1/repositories"
      ;;
      docker.io)
      echo "https://index.docker.io/v1/repositories"
      ;;
      *)
      echo "https://$1:5000/v1/repositories"
      ;;
   esac
}


function get_tags 
{
  repo=$1
  image=$2

  tagjson=$(curl -s $(repo_url $repo)/repositories/$image/tags)

  # take the tags from the json, and return a sorted list
  echo $tagjson | python -c "import json
import random
import string
import sys
from distutils.version import LooseVersion, StrictVersion


def json_cmp(a, b):
   av = a['name']
   bv = b['name']

   if av.startswith('v'):
     av = av[1:]

   if bv.startswith('v'):
     bv = bv[1:]

   if LooseVersion(av) > LooseVersion(bv):
      return -1
   elif LooseVersion(av) < LooseVersion(bv):
      return 1
   
   return 0


j = json.loads(sys.stdin.read())
j.sort(json_cmp)

for r in j:
   print r['name']
"

}

function cache_images
{
   repo=$1
   images=$2
   local_repo=$3
   max=$4
   mask=$5
   [[ "$mask" == "" ]] && mask="*"

   for image in "${images[@]}"
   do
      tags=get_tags $repo $images

      for tag in $tags
      do
   
         if [[ "$tag" == "$mask" ]]; then 

            docker pull $repo/$image:$tag

            if [ $? -eq 0 ]; then

               docker tag $repo/$image:$tag $local_repo/$image:$tag

               docker push $local_repo/$image:$tag

               [[ $? -ne 0 ]] && echo "*** ERROR: problem pushing $local_repo/$image:$tag"

               clean_up="$clean_up $local_repo/$image:$tag $repo/$image:$tag" 
            
            else
 
               echo "*** ERROR: problem pulling $repo/$image:$tag ($?)"

            fi

            counter=$((counter+1))
            [[ "$max" != "" ]] && [[ $counter -gt $max ]] && break

         else

            echo "*** SKIPPING: $repo/$image:$tag"

         fi

      done

      ## remove images in local docker registry
      docker rmi -f $clean_up
   
   done
}

image_list=$1
local_repo=$2
max_versions=$3
mask="$4"

case $image_list in

   redhat)

      cache_images $RH_REPO $RH_IMAGES $local_repo $max_versions "$mask"

   ;;

   docker)

      cache_images $DOCKER_REPO $DOCKER_IMAGES $local_repo $max_versions "$mask"
   ;;

   *)
   echo "Unsupported image list $image_list"
   ;;

esac
