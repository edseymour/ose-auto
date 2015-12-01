#!/bin/sh

cd /root/backup/openshift
DATE=`date +%Y%m%d.%H`
DIR=/root/backup/openshift/$DATE/projects
mkdir -p $DIR

# Backup object per project for easy restore
cd $DIR
for i in `oc get projects |grep Active |awk '{print $1}'`
do 
  oc export all --all -n $i >$i.yml
done

# Stuff that does not get backed-up by "all"
cd ..
for i in all templates namespaces projects pods
do 
  oc export $i --all-namespaces >$i.yml
done

# etcd database backup
etcdctl backup --data-dir /var/lib/openshift/openshift.local.etcd   --backup-dir etcd

# config files backup
mkdir files
rsync -va /etc/ansible/facts.d/openshift.fact \
          /etc/atomic-enterprise \
          /etc/corosync \
          /etc/ansible \
          /etc/etcd \
          /etc/openshift \
          /etc/openshift-sdn \
          /etc/origin \
          /etc/sysconfig/atomic-enterprise-master \
          /etc/sysconfig/atomic-enterprise-node \
          /etc/sysconfig/atomic-openshift-master \
          /etc/sysconfig/atomic-openshift-master-api \
          /etc/sysconfig/atomic-openshift-master-controllers \
          /etc/sysconfig/atomic-openshift-node \
          /etc/sysconfig/openshift-master \
          /etc/sysconfig/openshift-node \
          /etc/sysconfig/origin-master \
          /etc/sysconfig/origin-master-api \
          /etc/sysconfig/origin-master-controllers \
          /etc/sysconfig/origin-node \
          /etc/systemd/system/atomic-openshift-node.service.wants \
          /root/.kube \
          $HOME/.kube \
          /usr/lib/systemd/system/atomic-openshift-master-api.service \
          /usr/lib/systemd/system/atomic-openshift-master-controllers.service \
          /usr/lib/systemd/system/origin-master-api.service \
          /usr/lib/systemd/system/origin-master-controllers.service \
      files

