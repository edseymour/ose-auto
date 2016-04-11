#!/bin/bash

. functions.sh

for node in $hosts 
do

   fqdn=$(gen_fqdn $node)


IMAGES=(
jboss-webserver-3/tomcat7-openshift
jboss-webserver-3/tomcat8-openshift
jboss-eap-6/eap-openshift
jboss-amq-6/amq-openshift
openshift3/image-inspector
openshift3/jenkins-1-rhel7
openshift3/logging-auth-proxy
openshift3/logging-deployment
openshift3/logging-elasticsearch
openshift3/logging-fluentd
openshift3/logging-kibana
openshift3/metrics-cassandra
openshift3/metrics-deployer
openshift3/metrics-hawkular-metrics
openshift3/metrics-heapster
openshift3/mongodb-24-rhel7
openshift3/mysql-55-rhel7
openshift3/node
openshift3/nodejs-010-rhel7
openshift3/openvswitch
openshift3/ose
openshift3/ose-deployer
openshift3/ose-docker-builder
openshift3/ose-docker-registry
openshift3/ose-f5-router
openshift3/ose-haproxy-router
openshift3/ose-keepalived-ipfailover
openshift3/ose-pod
openshift3/ose-recycler
openshift3/ose-sti-builder
openshift3/perl-516-rhel7
openshift3/php-55-rhel7
openshift3/postgresql-92-rhel7
openshift3/python-33-rhel7
openshift3/ruby-20-rhel7
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
        sudo docker pull registry.access.redhat.com/$image:$tag
     fi
  done

done
done

