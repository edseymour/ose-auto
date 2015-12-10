#!/bin/bash

. functions.sh
validate_config httpProxy
validate_config httpsProxy
validate_config noProxy
validate_config_default

dockerfile=/etc/sysconfig/docker
HTTPS_PROXY_var="#HTTPS_PROXY=$httpsProxy"
HTTP_PROXY_var="#HTTP_PROXY=$httpProxy"
NO_PROXY_var="#NO_PROXY=$noProxy"

[[ ! "$target" == "" ]] && echo "overriding config and configuring for $target" && hosts=$target

echo "********** WARNING ****************"
echo "*** This script replaces all proxy config on hosts"
echo "**  If no proxy config exits it will insert. The script will insert the registry service ip address into the no_proxy for docker  "
echo "*** For each host : $hosts"
echo "*** For each master : $master"
echo "*******  files replaced *********"
echo "       - /etc/sysconfig/atomic-openshift-master "
echo "       - /etc/sysconfig/atomic-openshift-master-api"
echo "       - /etc/sysconfig/atomic-openshift-master-controllers"
echo "       - /etc/sysconfig/docker"


echo "*** Only proceed if you are absolutely sure that's what you want to do, CTRL-C to exit now"
read -p "Press any key to continue"

function install_prereqs
{
   fqdn=$1
   registry=$2
   # export the OSE_DEVICE variable
 scmd $ssh_user@$fqdn  "bash -c 'echo \"registry=${registry};  export registry\" > /etc/profile.d/registry.sh'"
 scmd $ssh_user@$fqdn  "bash -c 'echo \"HTTPS_PROXY_var=$HTTPS_PROXY_var;  export HTTPS_PROXY_var\" > /etc/profile.d/HTTPS_PROXY_var.sh'"

  scmd $ssh_user@$fqdn "bash -c 'echo \"HTTP_PROXY_var=$HTTP_PROXY_var;  export HTTP_PROXY_var\" > /etc/profile.d/HTTP_PROXY_var.sh'"

    scmd $ssh_user@$fqdn  "bash -c 'echo \"NO_PROXY_var="${NO_PROXY_var}";  export NO_PROXY_var\" > /etc/profile.d/NO_PROXY_var.sh'"

   scmd $ssh_user@$fqdn <<-\SSH

# install pre-requisites
dockerfile=/etc/sysconfig/docker
# configure docker options
sed -i "s/OPTIONS=.*/OPTIONS=\'--selinux-enabled --insecure-registry 172.30.0.0\/16\'/g" /etc/sysconfig/docker
echo " ****** Start Host $fqdn ******* "
echo " ** $HTTP_PROXY_var"
echo " ** $HTTPS_PROXY_var"
echo " ** $NO_PROXY_var"

## replace docker stuff

if [ -f $dockerfile ]; then
        echo " ****** Docker file found:  setting $dockerfile"
        grep -q 'HTTPS_PROXY' $dockerfile  && sed -i "s/.*HTTPS_PROXY.*/$HTTPS_PROXY_var/" $dockerfile || echo "$HTTPS_PROXY_var" >> $dockerfile
        grep -q 'HTTP_PROXY' $dockerfile  && sed -i "s/.*HTTP_PROXY.*/$HTTP_PROXY_var/" $dockerfile || echo "$HTTP_PROXY_var" >> $dockerfile
        grep -q 'NO_PROXY' $dockerfile  && sed -i "s/.*NO_PROXY.*/$NO_PROXY_var,$registry/" $dockerfile || echo "$NO_PROXY_var,$registry" >> $dockerfile
fi
## replace node, api, masters
for file in  /etc/sysconfig/atomic-openshift-*
do
        echo " ****** setting proxy  $file ****** "
         grep -q 'HTTPS_PROXY' $file  && sed -i "s/.*HTTPS_PROXY.*/$HTTPS_PROXY_var/g" $file || echo "$HTTPS_PROXY_var" >> $file
        grep -q 'HTTP_PROXY' $file  && sed -i "s/.*HTTP_PROXY.*/$HTTP_PROXY_var/g" $file || echo "$HTTP_PROXY_var" >> $file
        grep -q 'NO_PROXY' $file  && sed -i "s/.*NO_PROXY.*/$NO_PROXY_var/g" $file || echo "$NO_PROXY_var" >> $file
done
echo " ****** done **********


"
#end of script
exit
SSH

}
echo babababai
docker_registry=
for node in $master
do
   fqdn=$(gen_fqdn $node)
    docker_registry=`scmd $fqdn oc get service -n default  | grep docker-registry | awk '{print $2}'`
   echo breaking
 break
done
echo $docker_registry
for node in $hosts
do
   fqdn=$(gen_fqdn $node)

   install_prereqs $fqdn $docker_registry &

done

wait
