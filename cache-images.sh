#!/bin/bash

MAX_ASYNC=1

RH_REPO=registry.access.redhat.com
DOCKER_REPO=docker.io

RH_IMAGES_TEST=(openshift3/metrics-heapster)

OSE_IMAGES=(openshift3/ose-haproxy-router
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

DOCKER_IMAGES=(sonatype/nexus
redis
)

FABRIC8_IMAGES=(fabric8/fabric8                 
fabric8/fabric8-console         
fabric8/gogs                    
fabric8/eclipse-orion           
fabric8/fluentd-kubernetes      
fabric8/gerrit                  
fabric8/fabric8-java            
fabric8/jenkins                 
fabric8/nexus                   
fabric8/zookeeper               
fabric8/brackets                
fabric8/fabric8-forge           
fabric8/fabric8-hawtio-builder  
fabric8/fabric8-http-gateway    
fabric8/fabric8-jbpm-designer   
fabric8/fabric8-kiwiirc         
fabric8/fabric8-mq              
fabric8/fabric8-workflow-builder
fabric8/hubot-irc               
fabric8/hubot-slack             
fabric8/jenkins-docker          
fabric8/jenkins-jnlp-client     
fabric8/lets-chat               
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

  url=$(repo_url $repo)/$image/tags

  tagjson=$(curl -s $url)

  [[ "$tagjson" == "" ]] && return 0

  # take the tags from the json, and return a sorted list
  echo $tagjson | python -c "import json
import random
import string
import sys
from distutils.version import LooseVersion


def json_cmp(av, bv):

   if av.startswith('v'):
     av = av[1:]

   if bv.startswith('v'):
     bv = bv[1:]

   try:


     if LooseVersion(av) > LooseVersion(bv):
       return -1
     elif LooseVersion(av) < LooseVersion(bv):
       return 1

   except:

     if av == 'latest':
       return -1
     if bv == 'latest':
       return 1
   
     if av > bv:
       return -1
     elif av < bv:
       return 1

   
   return 0


j = json.loads(sys.stdin.read())
j = sorted(j, cmp=json_cmp)

for r in j:
   print r
"

}

function pull_and_push
{
   src=$1
   dst=$2
   
   echo "*** INFO: Pulling $src"
   docker pull $src

   if [ $? -eq 0 ]; then

      echo "*** INFO: tagging $src $dst"
      docker tag -f $src $dst

      echo "*** INFO: pushing $dst"
      docker push $dst

      [[ $? -ne 0 ]] && echo "*** ERROR: problem pushing $dst" && return 1

   else

      echo "*** ERROR: problem pulling $src ($?)"
      return 1

   fi

   return 0
}

function cache_images
{
   repo=$1
   declare -a images=("${!2}")
   local_repo=$3
   max=$4
   [[ "$max" == "" ]] && max=100
   mask=$5

   for image in "${images[@]}"
   do
      tags=$(get_tags $repo $image)
      counter=0
      total=0
      ic=0
      clean_up=

      for tag in $mask
      do
         [[ $tags != *"$tag"* ]] && echo "*** INFO: $tag not available for $image" && continue

         src=$repo/$image:$tag
         localimage=$(echo $image | cut -d'/' -f2-)
         dst=$local_repo/$localimage:$tag

         pull_and_push $src $dst

         if [[ $? -eq 0 ]]; then
           clean_up="$clean_up $src $dst" 
           total=$((total+1))
         fi


      done

      for tag in $tags
      do
         # if we already have this, then skip to next one
         [[ $mask == *"$tag"* ]] && continue 

         if [[ $counter -lt $max && ( $ic -lt $MAX_ASYNC || "$tag" != *"-"* ) ]] ; then 

            # count how many async releases we're pulling, we only want one per major release, so reset on majors
            if [[ "$tag" == *"-"* ]] ; then 
              ic=$((ic+1))
            else
              ic=0
            fi

            src=$repo/$image:$tag
            localimage=$(echo $image | cut -d'/' -f2-)
            dst=$local_repo/$localimage:$tag

            pull_and_push $src $dst

            if [[ $? -eq 0 ]]; then
              clean_up="$clean_up $src $dst" 
              total=$((total+1))
            fi

            counter=$((counter+1))

         else

            echo "*** SKIPPING: $repo/$image:$tag"

         fi

      done

      echo "*** INFO: cached $total images, cleaning up local Docker Engine"
      ## remove images in local docker registry
      [[ "$clean_up" != "" ]] && docker rmi -f $clean_up
   
   done
}

image_list=$1
local_repo=$2
max_versions=$3
mask="$4"

case $image_list in

   test)

      cache_images $RH_REPO RH_IMAGES_TEST[@] $local_repo $max_versions "$mask"

   ;;

   ose)

      cache_images $RH_REPO OSE_IMAGES[@] $local_repo $max_versions "$mask"

   ;;

   fabric8)
      cache_images $DOCKER_REPO FABRIC8_IMAGES[@] $local_repo $max_versions "$mask"

   ;;

   docker)

      cache_images $DOCKER_REPO DOCKER_IMAGES[@] $local_repo $max_versions "$mask"
   ;;

   *)
   echo "Unsupported image list $image_list"
   ;;

esac
