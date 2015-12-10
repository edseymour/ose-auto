#!/bin/bash

. functions.sh

validate_config_master

HAWKULAR_URL=$hawkular
MASTER_URL=$master_url
echo "use ./install-metrics.sh  -c .config/ose-auto.config --master_url=master.example.com --hawkular=hawkular.cloudapps.example.com "

fqdn="$master.$domain"
echo 2HHH $HAWKULAR_URL  $MASTER_URL
scmd $ssh_user@$fqdn  "bash -c 'echo \"HAWKULAR_URL=${HAWKULAR_URL};  export HAWKULAR_URL\" > /etc/profile.d/ose-device.sh'"
scmd $ssh_user@$fqdn  "bash -c 'echo \"MASTER_URL=${MASTER_URL};  export MASTER_URL\" >> /etc/profile.d/ose-device.sh'"

scmd $ssh_user@$fqdn <<-\SSH
oc project openshift-infra
oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API
 oadm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
oadm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster
oc secrets new metrics-deployer nothing=/dev/null

export contains=`grep "PUBLIC_MASTER_URL" /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/infrastructure-templates/enterprise/metrics-deployer.yaml |wc -l`

if [ $contains -eq 2 ]; then
echo '-
  description: "How many days metrics should be stored for."
  name: PUBLIC_MASTER_URL
  value: "7"' >> /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/infrastructure-templates/enterprise/metrics-deployer.yaml
fi

oc process -f /usr/share/ansible/openshift-ansible/roles/openshift_examples/files/examples/infrastructure-templates/enterprise/metrics-deployer.yaml -v \
HAWKULAR_METRICS_HOSTNAME=$HAWKULAR_URL,USE_PERSISTENT_STORAGE=false,IMAGE_PREFIX=openshift3/,IMAGE_VERSION=latest,PUBLIC_MASTER_URL=$MASTER_URL | oc create -f -


 sed -i '/servingInfo/i \
  metricsPublicURL: https://$HAWKULAR_URL/hawkular/metrics' /etc/origin/master/master-config.yaml

echo "you may want to restart master "



exit
SSH
