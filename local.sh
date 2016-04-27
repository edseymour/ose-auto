. /etc/rc.d/init.d/functions
#. /etc/profile.d/openshift.sh

OSE_MASTER_IP=192.168.1.82

# [ -f /etc/sysconfig/network ] && . /etc/sysconfig/network
systemctl status docker >/dev/null || systemctl start docker

new() 
{
        echo "Creating new OpenShift Enterprise environment: "

	# Prepare directories for bind-mounting
	dirs=(openshift.local.volumes openshift.local.config openshift.local.etcd)
	for d in ${dirs[@]}; do
	  mkdir -p /var/lib/origin/${d} && chcon -Rt svirt_sandbox_file_t /var/lib/origin/${d}
	done

        ip addr add ${OSE_MASTER_IP}/32 dev lo:0
        systemctl stop dnsmasq
        systemctl stop avahi-daemon.service
        systemctl stop avahi-daemon.socket
        iptables -I INPUT -p udp --dport 53 -j ACCEPT

        docker pull registry.access.redhat.com/openshift3/ose-pod
        docker pull registry.access.redhat.com/openshift3/ose-haproxy-router
        docker pull registry.access.redhat.com/openshift3/ose-docker-builder
        docker pull registry.access.redhat.com/openshift3/ose-deployer
        docker pull registry.access.redhat.com/openshift3/ose-docker-registry
        docker pull registry.access.redhat.com/openshift3/ose
        docker tag -f registry.access.redhat.com/openshift3/ose openshift3/ose
        docker run -d --name "ose" --privileged --net=host --pid=host \
         -v /:/rootfs:ro \
         -v /var/run:/var/run:rw \
         -v /sys:/sys:ro \
         -v /var/lib/docker:/var/lib/docker:rw \
         -v /var/lib/origin/openshift.local.volumes:/var/lib/origin/openshift.local.volumes:z \
         -v /var/lib/origin/openshift.local.config:/var/lib/origin/openshift.local.config:z \
         -v /var/lib/origin/openshift.local.etcd:/var/lib/origin/openshift.local.etcd:z \
         openshift3/ose start \
          --master="https://${OSE_MASTER_IP}:8443" \
          --etcd-dir="/var/lib/origin/openshift.local.etcd" \
          --hostname=`hostname` \
          --cors-allowed-origins=.*
#          --latest-images=true \

	sleep 15 # Give OpenShift 15 seconds to start

	state=$(docker inspect -f "{{.State.Running}}" ose)
	if [[ "${state}" != "true" ]]; then
	  >&2 echo "[ERROR] OpenShift failed to start:"
	  docker logs ose
	  exit 1
	fi

	binaries=(oc oadm)
	for n in ${binaries[@]}; do
	  echo "[INFO] Copy the OpenShift '${n}' binary to host /usr/bin/${n}..."
	  docker run --rm --entrypoint=/bin/cat openshift3/ose /usr/bin/${n} > /usr/bin/${n}
	  docker run --rm --entrypoint=/bin/cat openshift3/ose /etc/bash_completion.d/${n} > /etc/bash_completion.d/${n}
	  chmod +x /usr/bin/${n}
	done

	# Create Docker Registry
	echo "[INFO] Configure Docker Registry ..."
	oadm registry --create --credentials=/var/lib/origin/openshift.local.config/master/openshift-registry.kubeconfig

	# For router, we have to create service account first and then use it for
	# router creation.
	echo "[INFO] Configure HAProxy router ..."
	echo '{"kind":"ServiceAccount","apiVersion":"v1","metadata":{"name":"router"}}' \
	  | oc create -f -
	oc get scc privileged -o json \
	  | sed '/\"users\"/a \"system:serviceaccount:default:router\",'  \
	  | oc replace scc privileged -f -
	oadm router --create --credentials=/var/lib/origin/openshift.local.config/master/openshift-router.kubeconfig \
	  --service-account=router

#                 https://github.com/jorgemoralespou/osev3-examples/blob/master/spring-boot/springboot-sti/springboot-sti-all.json \
#                 https://github.com/jorgemoralespou/osev3-examples/blob/master/wildfly-swarm/wildfly-swarm-s2i/wildfly-swarm-s2i-all.json \
	  echo "[INFO] Install OpenShift templates ..."
	  for url in https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-rhel7.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/image-streams/image-streams-centos7.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/wordpress/template/wordpress-mysql.json  \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-ephemeral-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mongodb-persistent-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-persistent-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-ephemeral-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/postgresql-persistent-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-ephemeral-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/jenkins/jenkins-persistent-template.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-custombuild.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-dockerbuild.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-pullspecbuild.json \
	             https://raw.githubusercontent.com/openshift/origin/master/examples/sample-app/application-template-stibuild.json \
	             https://raw.githubusercontent.com/openshift/nodejs-ex/master/openshift/templates/nodejs-mongodb.json \
	             https://raw.githubusercontent.com/openshift/nodejs-ex/master/openshift/templates/nodejs.json \
                 https://raw.githubusercontent.com/jboss-openshift/application-templates/master/jboss-image-streams.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-basic-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-https-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-mongodb-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-mongodb-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-mysql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-mysql-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-postgresql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat7-postgresql-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-basic-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-https-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-mongodb-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-mongodb-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-mysql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-mysql-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-postgresql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/webserver/jws30-tomcat8-postgresql-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq62-basic.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq62-persistent-ssl.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq62-persistent.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/amq/amq62-ssl.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-basic.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-https.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-mysql-persistent.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-mysql.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-postgresql-persistent.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/datagrid/datagrid65-postgresql.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/decisionserver/decisionserver62-amq-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/decisionserver/decisionserver62-basic-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/decisionserver/decisionserver62-https-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-amq-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-amq-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-basic-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-https-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-mongodb-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-mongodb-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-mysql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-mysql-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-postgresql-persistent-s2i.json \
	             https://raw.githubusercontent.com/jboss-openshift/application-templates/master/eap/eap64-postgresql-s2i.json \
	             https://raw.githubusercontent.com/jboss-fuse/application-templates/master/fis-image-streams.json \
	             https://raw.githubusercontent.com/PatrickSteiner/xpaas/master/quickstart-template.json \
	             https://raw.githubusercontent.com/christian-posta/fis-hello/master/quickstart-template.json \
	             https://raw.githubusercontent.com/jorgemoralespou/osev3-examples/master/all-in-v3.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/amqbroker.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/apiman.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/api-registry.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/artifactory.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/brackets.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/cd-pipeline.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/cdelivery-core.json \
	             http://central.maven.org/maven2/io/fabric8/devops/packages/cdelivery-core/2.2.26/cdelivery-core-2.2.26-kubernetes.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/cdelivery.json \
	             http://central.maven.org/maven2/io/fabric8/devops/packages/cdelivery/2.2.26/cdelivery-2.2.26-kubernetes.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/chaos-monkey.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/chat-irc.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/chat-letschat.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/chat-slack.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/chat.json \
	             http://central.maven.org/maven2/io/fabric8/devops/packages/chat/2.2.26/chat-2.2.26-kubernetes.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/fabric8mq-consumer.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/fabric8mq-producer.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/fabric8mq.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/gerrit.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/gogs.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/grafana2.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/hubot-irc.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/hubot-letschat.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/hubot-notifier.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/hubot-slack.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/image-linker.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/keycloak.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/kibana.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/letschat.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/logging.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/management.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/metrics.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/nexus.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/orion.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/prometheus.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/qpid-dispatch.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/social.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/sonarqube.json \
	             https://raw.githubusercontent.com/fabric8io/templates/master/default/template/taiga.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/cdi/camel-http/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/cdi/camel-jetty/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/cdi/camel-mq/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/cdi/camel/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/cdi/cxf/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/java/fatjar/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/java/mainclass/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/karaf/camel-amq/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/karaf/camel-log/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/karaf/camel-rest-sql/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/karaf/cxf-rest/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/spring-boot/webmvc/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/spring-boot/camel/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/spring/camel/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/war/camel-servlet/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/war/cxf-cdi-servlet/quickstart-template.json \
	             https://raw.githubusercontent.com/fabric8io/ipaas-quickstarts/master/quickstart/war/wildfly/quickstart-template.json \
	             https://raw.githubusercontent.com/jpechane/openshift-gitlab/master/gitlab-image-streams.json \
	             https://raw.githubusercontent.com/jpechane/openshift-gitlab/master/gitlab-application-templates.json ; do
	    oc create -f $url -n openshift
	  done
          oc delete bc,dc,rc,pods --all -n openshift

	echo "[INFO] Create 'admin' user"
        mkdir -p ~/.kube &>/dev/null
        [ -f ~/.kube/config ] && mv ~/.kube/config ~/.kube/config.old
        chmod a+rw /var/lib/origin/openshift.local.config/master/admin.kubeconfig
        ln -s /var/lib/origin/openshift.local.config/master/admin.kubeconfig ~/.kube/config
	oadm policy add-role-to-user view admin --config=/var/lib/origin/openshift.local.config/master/admin.kubeconfig
	#oc login https://${OSE_MASTER_IP}:8443 -u admin \
	#   --certificate-authority=/var/lib/origin/openshift.local.config/master/ca.crt
	echo
	echo "You can now access OpenShift console on: https://${OSE_MASTER_IP}:8443/console"
	echo
	echo "To browse the OpenShift API documentation, follow this link:"
	echo "http://openshift3swagger-claytondev.rhcloud.com"
	echo
	echo "Then enter this URL:"
	echo https://${OSE_MASTER_IP}:8443/swaggerapi/oapi/v1
	echo "."

	RETVAL=$?
        echo
	[ $RETVAL = 0 ] && touch /var/lock/subsys/ose
	return $RETVAL
}


fabric8()
{
	  echo "[INFO] Installing Fabric8 ..."
          oc new-project fabric8
	  for url in https://raw.githubusercontent.com/fabric8io/templates/master/default/template/console-kubernetes.json \
                     https://raw.githubusercontent.com/fabric8io/templates/master/default/template/jenkins.json ; do
	    oc create -f $url -n fabric8
	  done
}


destroy()
{
        echo "Destroying existing OpenShift Enterprise environment: "
        docker rm "ose" &>/dev/null
        rm -rf /var/lib/origin
}

start() 
{
        echo "Starting OpenShift Enterprise: "
        ip addr add ${OSE_MASTER_IP}/32 dev lo:0
        iptables -I INPUT -p udp --dport 53 -j ACCEPT
        systemctl stop dnsmasq
        systemctl stop avahi-daemon.service
        systemctl stop avahi-daemon.socket

        docker start "ose"
	RETVAL=$?
        echo
	[ $RETVAL = 0 ] && touch /var/lock/subsys/ose
	return $RETVAL
}

stop() 
{
        echo "Shutting down OpenShift Enterprise: "
	docker ps -f NAME=ose |grep ose && docker stop "ose" && sleep 15 # Give OpenShift 15 seconds to stop
        docker ps -f NAME=k8s --format="{{.Names}}" |xargs -r docker stop
        sudo umount -R /var/lib/origin/openshift.local.volumes/pods/*/volumes/*/* 2>/dev/null
        ip addr del ${OSE_MASTER_IP}/32 dev lo:0 2>/dev/null
	RETVAL=$?
	rm -f  /var/lock/subsys/ose
        echo
	return $RETVAL
}

status()
{
        echo "Status of OpenShift Enterprise: "
        docker ps -a -f NAME=ose
	RETVAL=$?
        return $RETVAL
}

# See how we were called.
case "$1" in
  new)
        stop
        destroy
	new
        ;;
  destroy)
        stop
	destroy
        ;;
  fabric8)
	fabric8
        ;;
  start)
	start
        ;;
  stop)
	stop
        ;;
  force-reload|restart|reload)
	stop
	start
	;;
  try-restart|condrestart)
	[ -e /var/lock/subsys/ose ] && (stop; start)
	;;
  status)
  	status
	;;
  *)
        echo "Usage: $0 {new|destroy|fabric8|start|stop|status|restart|reload|condrestart}"
        exit 3
esac

exit $RETVAL

