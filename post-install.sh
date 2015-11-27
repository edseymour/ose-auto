#!/bin/bash

. functions.sh

validate_config_master

fqdn="$master.$domain"

scmd $ssh_user@$fqdn <<-\SSH

sudo -i

oadm manage-node $(oc get nodes | tail -n +2 | awk '{print $1}') --schedulable=true

oadm registry --dry-run --config=/etc/origin/master/admin.kubeconfig  \
--credentials=/etc/origin/master/openshift-registry.kubeconfig \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
--service-account=registry --mount-host=/mnt/registry

if [ $? -ne 0 ]; then

   echo "*** Creating default registry ***"
   [ ! -d /mnt/registry ] && sudo mkdir -p /mnt/registry ; # simple mount point for registry

   # not needed as SA is in priv scc, but would be better to move to new mounts host scc
   chcon -Rt svirt_sandbox_file_t /mnt/registry 

   # create the registry
   oadm registry --config=/etc/origin/master/admin.kubeconfig  \
   --credentials=/etc/origin/master/openshift-registry.kubeconfig \
   --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
   --service-account=registry --mount-host=/mnt/registry

else

   echo "*** Registry already exists ***"

fi


oadm router router --dry-run \
    --credentials='/etc/origin/master/openshift-router.kubeconfig' \
    --service-account=router

if [ $? -ne 0 ]; then
  echo "*** Creating default router ***"
  oadm router router --replicas=1    \
  --credentials='/etc/origin/master/openshift-router.kubeconfig' \
  --service-account=router
else
  echo "*** Router already exists ***"
fi

exit ; # quit sudo

exit
SSH



