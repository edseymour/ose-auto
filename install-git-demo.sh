#!/bin/bash

## Script borrowed and adapted from https://github.com/RedHatEMEA/demobuilder

. functions.sh

validate_config target

scmd $ssh_user@$target <<-\SSH

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
echo 'Triggering OSE3 build...'
curl -sX POST "https://\$PUB_HOST:8443/osapi/v1beta3/namespaces/demo/buildconfigs/$(basename $i)/webhooks/secret/generic"
EOF
  chmod 0755 /var/lib/git/demo/$(basename $i)/hooks/post-receive
  chown -R nobody:nobody /var/lib/git
done

exit ; # exit sudo

exit ; # exit ssh

SSH
