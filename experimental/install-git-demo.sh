#!/bin/bash

## Script borrowed and adapted from https://github.com/RedHatEMEA/demobuilder

. functions.sh

validate_config target
validate_config jboss_installer

sscp $jboss_installer $ssh_user@$target:jboss-installer.jar

scmd $ssh_user@$target <<-\SSH

sudo mv jboss-installer.jar /root/

sudo subscription-manager repos --enable=rhel-7-server-optional-rpms --enable=rhel-server-rhscl-7-rpms

sudo yum install -y git-daemon unzip scl-utils maven30

wget https://raw.githubusercontent.com/RedHatEMEA/demobuilder/master/layers/rhel-server-7%3Agui%3Aose-3.0%3Aoffline/%40target/gitdaemon-rw-net.pp
wget https://raw.githubusercontent.com/RedHatEMEA/demobuilder/master/layers/rhel-server-7%3Agui%3Aose-3.0%3Aoffline/%40target/gitdaemon-rw-net.te
sudo semodule -i gitdaemon-rw-net.pp

sudo bash -c "cat <<EOF > /etc/gitconfig
[daemon]
receivepack = true
EOF"

sudo rm /lib/systemd/system/git.service
sudo bash -c "cat <<EOF > /lib/systemd/system/git@.service
[Unit]
Description=Git Repositories Server Daemon
Documentation=man:git-daemon(1)

[Service]
User=nobody
ExecStart=-/usr/libexec/git-core/git-daemon --base-path=/var/lib/git --export-all --user-path=public_git --syslog --inetd --verbose
StandardInput=socket
EOF"

sudo systemctl enable git.socket
sudo systemctl start git.socket

# Figure out the public IP and hostname set for this session and subsequent sessions
PUB_IP=$(curl -s http://myip.dnsomatic.com)
export PUB_IP
PUB_HOST=$PUB_IP

thost=$(host $PUB_IP)
[ $? -eq 0 ] && PUB_HOST=$(echo $thost | awk '{print $5}' | sed 's/\.$//g')
export PUB_HOST

sudo bash -c "cat <<EOF > /etc/profile.d/pub-info.sh
export PUB_IP=$PUB_IP
export PUB_HOST=$PUB_HOST
EOF"

# now install Jim Minter's example projects
COMMIT=d816670ae2f2883b7560272a2fdee67760563387
curl -sLO https://github.com/jim-minter/ose3-demos/archive/$COMMIT.zip
unzip -o -q $COMMIT.zip
sudo mv ose3-demos-$COMMIT/* /home/demo
sudo chown -R demo:demo /home/demo

sudo -i

su - demo -c "git config --global user.email 'demo@$PUB_HOST' ; git config --global user.name 'Demo'"

for i in /home/demo/git/*
do
  git init --bare /var/lib/git/demo/$(basename $i)
  chown -R nobody:nobody /var/lib/git

  pushd $i
  git init
  git add -A
  git commit -m 'Initial commit'
  git remote add origin git://localhost/demo/$(basename $i)
  git push -u origin master

  chown -R demo:demo $i

  if [ -e pom.xml ]; then
    BUILD="$BUILD $(basename $i) $i"
    su - demo -c "scl enable maven30 'cd $i && mvn clean package'"
    rm -rf target
  fi

  popd

  cat >/var/lib/git/demo/$(basename $i)/hooks/post-receive <<EOF
#!/bin/bash
echo 'Triggering OpenShift 3.1 build...'
curl -sX POST "https://\$PUB_HOST:8443/oapi/v1/namespaces/demo/buildconfigs/$(basename $i)/webhooks/secret/generic"
EOF
  chmod 0755 /var/lib/git/demo/$(basename $i)/hooks/post-receive
  chown -R nobody:nobody /var/lib/git
done

## install the monster templates
sed -i '/http\:\/\/openshift\.example\.com\:8080/d' /home/demo/git/monster/openshift/ticket-monster-template.yaml
sed -i '/http_proxy/d' /home/demo/git/monster/openshift/ticket-monster-template.yaml
sed -i '/https_proxy/d' /home/demo/git/monster/openshift/ticket-monster-template.yaml
sed -i "s|openshift\.example\.com|$PUB_HOST|g" /home/demo/git/monster/openshift/ticket-monster-template.yaml
sed -i 's|jboss-eap6-openshift\:6\.4|jboss-eap64-openshift:1.1|g' /home/demo/git/monster/openshift/ticket-monster-template.yaml

oc create -f /home/demo/git/monster/openshift/ticket-monster-template.yaml -n openshift
oc create -f /home/demo/git/monster/openshift/ticket-monster-prod-template.yaml -n openshift



cat <<EOF > InstallConfigRecord.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
<com.jboss.devstudio.core.installer.HTMLInfoPanelWithRootWarning id="introduction"/>
<com.izforge.izpack.panels.HTMLLicencePanel id="licence"/>
<com.jboss.devstudio.core.installer.PathInputPanel id="target">
<installpath>/usr/local/jbdevstudio</installpath>
</com.jboss.devstudio.core.installer.PathInputPanel>
<com.jboss.devstudio.core.installer.JREPathPanel id="jre"/>
<com.jboss.devstudio.core.installer.JBossAsSelectPanel id="as">
<installgroup>jbds</installgroup>
</com.jboss.devstudio.core.installer.JBossAsSelectPanel>
<com.jboss.devstudio.core.installer.UpdatePacksPanel id="updatepacks"/>
<com.jboss.devstudio.core.installer.DiskSpaceCheckPanel id="diskspacecheck"/>
<com.izforge.izpack.panels.SummaryPanel id="summary"/>
<com.izforge.izpack.panels.InstallPanel id="install"/>
<com.jboss.devstudio.core.installer.CreateLinkPanel id="createlink">
<jrelocation>/usr/lib/jvm/jre-1.8.0-openjdk/bin/java</jrelocation>
</com.jboss.devstudio.core.installer.CreateLinkPanel>
<com.izforge.izpack.panels.ShortcutPanel id="shortcut">
<programGroup name=""/>
<shortcut KdeSubstUID="false" categories="Applications;Development;" commandLine="" createForAll="true" description="Runs the Red Hat JBoss Developer Studio 8.1.0.GA" encoding="UTF-8" group="false" icon="/usr/local/jbdevstudio/studio/48-jbds_icon.png" iconIndex="0" initialState="1" mimetype="" name="Red Hat JBoss Developer Studio 8.1.0.GA" target="/usr/local/jbdevstudio/studio/jbdevstudio" terminal="false" terminalOptions="" tryexec="" type="Application" url="" usertype="0" workingDirectory="/usr/local/jbdevstudio/studio"/>
<shortcut KdeSubstUID="false" categories="Applications;Development;" commandLine="" createForAll="true" description="Runs the Red Hat JBoss Developer Studio 8.1.0.GA" encoding="UTF-8" group="true" icon="/usr/local/jbdevstudio/studio/48-jbds_icon.png" iconIndex="0" initialState="1" mimetype="" name="Red Hat JBoss Developer Studio 8.1.0.GA" target="/usr/local/jbdevstudio/studio/jbdevstudio" terminal="false" terminalOptions="" tryexec="" type="Application" url="" usertype="0" workingDirectory="/usr/local/jbdevstudio/studio"/>
<shortcut KdeSubstUID="false" categories="Applications;Development;" commandLine="-jar &quot;/usr/local/jbdevstudio/Uninstaller/uninstaller.jar&quot;" createForAll="true" description="Uninstall Red Hat JBoss Developer Studio 8.1.0.GA" encoding="UTF-8" group="true" icon="/usr/local/jbdevstudio/studio/48-jbds_uninstall_icon.png" iconIndex="0" initialState="1" mimetype="" name="Uninstall Red Hat JBoss Developer Studio 8.1.0.GA" target="java" terminal="false" terminalOptions="" tryexec="" type="Application" url="" usertype="0" workingDirectory="/usr/local/jbdevstudio/Uninstaller"/>
</com.izforge.izpack.panels.ShortcutPanel>
<com.jboss.devstudio.core.installer.ShortcutPanelPatch id="shortcutpatch"/>
<com.izforge.izpack.panels.SimpleFinishPanel id="finish"/>
</AutomatedInstallation>
EOF

java -jar jboss-installer.jar InstallConfigRecord.xml

cat <<EOF >"/usr/share/applications/Red Hat JBoss Developer Studio 8.1.0.GA.desktop"
[Desktop Entry]
Categories=Applications;Development;
Comment=Runs the Red Hat JBoss Developer Studio 8.1.0.GA
Comment[en]=Runs the Red Hat JBoss Developer Studio 8.1.0.GA
Encoding=UTF-8
Exec=/usr/local/jbdevstudio/studio/jbdevstudio
GenericName=
GenericName[en]=
Icon=/usr/local/jbdevstudio/studio/48-jbds_icon.png
MimeType=
Name=Red Hat JBoss Developer Studio 8.1.0.GA
Name[en]=Red Hat JBoss Developer Studio 8.1.0.GA
Path=/usr/local/jbdevstudio/studio
ServiceTypes=
SwallowExec=
SwallowTitle=
Terminal=false
TerminalOptions=
Type=Application
URL=
X-KDE-SubstituteUID=false
X-KDE-Username=root
EOF

install -m 0755 -o demo "/usr/share/applications/Red Hat JBoss Developer Studio 8.1.0.GA.desktop" /home/demo/Desktop

curl -sLO https://github.com/jim-minter/eclipse-importer/raw/master/com.redhat.importer_1.0.0.201509031446.jar
mv com.redhat.importer_1.0.0.201509031446.jar /usr/local/jbdevstudio/studio/plugins/

yum -y install xorg-x11-server-Xvfb

su - demo -c "xvfb-run /usr/local/jbdevstudio/jbdevstudio -data workspace $BUILD"

yum -y history undo $(yum history list | grep -A1 ^- | tail -1 | awk '{print $1;}')
rm -f /usr/local/jbdevstudio/studio/plugins/com.redhat.importer_1.0.0.201509031446.jar

exit ; # exit sudo
exit ; # exit ssh

SSH
