#!/bin/bash


IMAGES=(
fabric8/fabric8-console         
fabric8/fabric8                 
fabric8/gogs                    
fabric8/fluentd-kubernetes      
fabric8/gerrit                  
fabric8/eclipse-orion           
fabric8/fabric8-java            
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
fabric8/jenkins                 
fabric8/jenkins-docker          
fabric8/jenkins-jnlp-client     
fabric8/lets-chat               
)

for image in "${IMAGES[@]}"; do

  tagjson=$(curl -s https://index.docker.io/v1/repositories/$image/tags)

  tags=$(echo $tagjson | python -c "import json
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
")

  #  tags=$(echo $tags| tr " " "\n" | sort -r)

  echo "found the following tags: $tags"

  #echo "press any key to continue"
  #read

  counter=0

  for tag in $tags; do

    echo "prefetching $image:$tag"
    docker pull docker.io/$image:$tag


    counter=$counter+1
    [[ $counter -gt 1 ]] && break

  done

done



