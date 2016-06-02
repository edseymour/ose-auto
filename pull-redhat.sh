#!/bin/bash

images_meta=$(curl -s -H 'Accept: application/json' https://registry.access.redhat.com/crane/repositories)

images=$(echo $images_meta | python -c "import json
import random
import string
import sys
from distutils.version import LooseVersion, StrictVersion


def string_ver(ver)

   ## remove the preceeding v (see fabric8 inconsistent use
   if ver.startswith('v'):
     ver = ver[1:]

   return ver


def json_cmp(a, b):
   av = strip_ver(a['name'])
   bv = strip_ver(b['name'])

   if LooseVersion(av) > LooseVersion(bv):
      return -1
   elif LooseVersion(av) < LooseVersion(bv):
      return 1

   return 0



for image in "${IMAGES[@]}"; do
on.loads(sys.stdin.read())
j.sort(json_cmp)

for r in j:
   print r['name']
")



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



