#!/bin/bash -ex

PUBIP=$PUB_IP
PRIVIP=$(ip -4 addr show dev eth0 | sed -n '/inet / { s!.*inet !!; s!/.*!!; p; }')
OLDHN=ec2-54-76-190-81.eu-west-1.compute.amazonaws.com
NEWHN=$PUB_HOST
PATHS="/etc/hostname /etc/origin /home/demo/.kube/config /home/demo/.m2/settings.xml /home/demo/git /root/.kube/config /usr/lib64/firefox/firefox.cfg /usr/share/doc/demobuilder"

stop() {
  systemctl stop atomic-openshift-node
  # oc project default
  # oc delete pods --all
  systemctl stop atomic-openshift-master
  systemctl stop docker
  umount /var/lib/origin/openshift.local.volumes/pods/*/volumes/*/*
}

start() {
  systemctl start docker
  docker ps -aq |xargs docker rm -f || true
  ./openshift-master-ipcfg.py 
  systemctl start atomic-openshift-master
  oc delete hostsubnet $(oc get hostsubnet | tail -n+2 | grep -v $PRIVIP | awk '{print $1}') || true
  ./openshift-node-ipcfg.py 
  systemctl start atomic-openshift-node
}

save() {
  for i in $PATHS /var/lib/origin; do
    [ -e $i-clean ] || cp -a $i $i-clean
  done
}

reset() {
  for i in $PATHS /var/lib/origin; do
    rm -rf $i
    cp -a $i-clean $i
  done
}

stop

sleep 10

find $PATHS -type f | xargs sed -i -e "s/${OLDHN//./\\.}/$NEWHN/g"
find $PATHS -type f | xargs sed -i -e "s/${OLDHN//./-}/${NEWHN//./-}/g"
find $PATHS -type f | xargs sed -i -e "s/$PRIVIP/$PUBIP/g"

sleep 10 

for old in $(find $PATHS -type d | sort -r); do
  new=$(echo $old | sed -e "s/${OLDHN//./\\.}/$NEWHN/g")
  [ $old = $new ] || mv $old $new
done
for old in $(find $PATHS -type f | sort -r); do
  new=$(echo $old | sed -e "s/${OLDHN//./\\.}/$NEWHN/g")
  [ $old = $new ] || mv $old $new
done

sleep 10

rm -f /etc/dhcp/dhclient-eth0-up-hooks
sed -i -e "/$OLDHN/ d" /etc/hosts

sleep 10 

python -c 'import random; print random.randint(11, 1000000000)' >/etc/origin/master/ca.serial.txt
./openshift-aws-crypto.py $NEWHN

sleep 10

hostname $NEWHN

sleep 10 

sed -i -e '/hostsubnet/ d' openshift-node-ipcfg.py

sleep 10 

start

sleep 10

oc delete node $OLDHN

sleep 10 

oc get templates -n openshift -o json >/tmp/json
oc delete templates -n openshift --all
sed -e "s/${OLDHN//./\\.}/$NEWHN/g" /tmp/json | oc create -n openshift -f -

sleep 10

for i in docker-registry router; do
  oc delete dc $i
  oc delete svc $i
done

sleep 10

oadm registry --config=/etc/origin/master/admin.kubeconfig --credentials=/etc/origin/master/openshift-registry.kubeconfig --mount-host=/registry --service-account=registry --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

sleep 5

oadm router --credentials=/etc/origin/master/openshift-router.kubeconfig --service-account=router --images='registry.access.redhat.com/openshift3/ose-${component}:${version}'

sleep 10

oc delete pod $(oc get pods | grep image-registry | awk '{print $1;}')

sleep 10

for i in /home/demo/git/*; do
  pushd $i
  rm -rf .git
  git init
  git add -A
  git commit -m 'Initial commit'
  git remote add origin git://localhost/demo/$(basename $i)
  git push -f -u origin master
  popd
done

sleep 10

chown -R demo:demo /home/demo

echo 'Done.'
echo "https://$(hostname):8443/"
echo 'dont forget to set the password for the demo user, and warm up the EBS volume'
