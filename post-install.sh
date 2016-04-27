#!/bin/bash -x

. functions.sh

validate_config_master
validate_config selector "used to designate nodes available for running the infrastructure services"

fqdn=$(gen_fqdn $master)

scmd $ssh_user@$fqdn bash -c "

sudo -i

# oadm manage-node $(oc get nodes | tail -n +2 | awk '{print $1}') --schedulable=true

oadm registry --dry-run --config=/etc/origin/master/admin.kubeconfig  \
--credentials=/etc/origin/master/openshift-registry.kubeconfig \
--images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
--service-account=registry --mount-host=/mnt/registry --selector='$selector'

if [ $? -ne 0 ]; then

   echo '*** Creating default registry ***'
   [ ! -d /mnt/registry ] && sudo mkdir -p /mnt/registry ; # simple mount point for registry

   # not needed as SA is in priv scc, but would be better to move to new mounts host scc
   chcon -Rt svirt_sandbox_file_t /mnt/registry 

   # create the registry
   oadm registry --config=/etc/origin/master/admin.kubeconfig  \
   --credentials=/etc/origin/master/openshift-registry.kubeconfig \
   --images='registry.access.redhat.com/openshift3/ose-${component}:${version}' \
   --service-account=registry --mount-host=/mnt/registry --selector='$selector'

else

   echo '*** Registry already exists ***'

fi


oadm router router --dry-run \
    --credentials='/etc/origin/master/openshift-router.kubeconfig' \
    --service-account=router --selector=$selector

if [ $? -ne 0 ]; then
  echo '*** Creating default router ***'
  oadm router router --replicas=1    \
  --credentials='/etc/origin/master/openshift-router.kubeconfig' \
  --service-account=router --selector=$selector
else
  echo '*** Router already exists ***'
fi

exit ; # sudo
"



