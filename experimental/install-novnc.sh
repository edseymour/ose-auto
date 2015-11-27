#!/bin/bash

. functions.sh

validate_config target

scmd $ssh_user@$target <<-\SSH

sudo -i

yum install -y unzip

wget https://github.com/edseymour/ose-vnc/archive/master.zip
unzip master.zip
cd ose-vnc-master/
docker build -t openshift/ose-vnc .

[ $(oc project | grep vnc | wc -l) -gt 0 ] && oc delete project vnc && sleep 5
oadm new-project vnc --admin=system:admin
oc project vnc

cat <<EOF | oc create -f -
apiVersion: v1
kind: Template
metadata:
  annotations:
    description: |
      Embedded noVNC client and websockify proxy for OpenShift All-In-One demo
    tags: instant-app,util
  name: novnc
objects:
- apiVersion: v1
  kind: DeploymentConfig
  metadata:
    name: novnc
  spec:
    replicas: 1
    selector:
      deploymentConfig: novnc
    strategy:
      resources: {}
      type: Recreate
    template:
      metadata:
        labels:
          deploymentConfig: novnc
        name: novnc
      spec:
        containers:
        - env:
          - name: HOSTPORT
            value: $(hostname):5900
          image: openshift/ose-vnc
          name: novnc
          ports:
          - containerPort: 6080
            protocol: TCP
          resources: {}
    triggers:
    - type: ConfigChange
    - imageChangeParams:
        automatic: true
        containerNames:
        - novnc
        from:
          kind: ImageStream
          name: novnc
      type: ImageChange
- apiVersion: v1
  kind: Service
  metadata:
    name: novnc
  spec:
    ports:
    - name: 6080-tcp
      nodePort: 0
      port: 6080
      protocol: TCP
    selector:
      deploymentConfig: novnc
- apiVersion: v1
  kind: Route
  metadata:
    name: desktop
  spec:
    tls:
      termination: edge
    to:
      kind: Service
      name: novnc
EOF

oc new-app novnc 
oc deploy novnc --latest

oc get route desktop -o yaml | sed "s/host:.*/host: desktop.$PUB_IP.xip.io/g" | oc replace -f -


exit ; # logout from sudo

exit ; # logout from ssh


SSH



