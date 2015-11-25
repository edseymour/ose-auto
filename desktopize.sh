#!/bin/bash

# This script is shamelessly ripped off from https://github.com/RedHatEMEA/demobuilder
# It will install a linux desktop and configure shortcuts for a new user 'demo'. It also sets up a VNC server listening on 5900. 

. functions.sh

scmd $ssh_user@$target <<-\SSH

echo "*** Installing desktop packages ***"
sudo yum install -y bash-completion evince firefox gnome-classic-session gnome-terminal man-db tigervnc-server xinetd xorg-x11-drivers

echo "*** Making default startup target the desktop environment ***"
sudo ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target

echo "*** Configuring gnome ***"
sudo mkdir -p /etc/gnome-settings-daemon/xrandr
sudo bash -c "cat <<EOF > /etc/gnome-settings-daemon/xrandr/monitors.xml
<monitors version="1">
  <configuration>
    <clone>no</clone>
    <output name="default">
      <vendor>???</vendor>
      <product>0x0000</product>
      <serial>0x00000000</serial>
      <width>1024</width>
      <height>768</height>
      <rate>60</rate>
      <x>0</x>
      <y>0</y>
      <rotation>normal</rotation>
      <reflect_x>no</reflect_x>
      <reflect_y>no</reflect_y>
      <primary>yes</primary>
    </output>
  </configuration>
</monitors>
EOF
"

echo "*** Configure Gnome Login ***"
sudo sed -i -e '/^\[greeter\]/ a \
IncludeAll=false\
Include=demo
/^\[xdmcp\]/ a \
Enable=true' /etc/gdm/custom.conf

echo "*** Create the VNC service ***"
sudo bash -c "cat <<EOF > /etc/xinetd.d/rfb
service rfb
{
        protocol = tcp
        wait = no
        user = nobody
        server = /usr/bin/Xvnc
        # the :1 below is due to bz1283925
        server_args = :1 -inetd -query localhost -once -SecurityTypes None
}
EOF
"

sudo bash -c "cat <<EOF > /etc/polkit-1/rules.d/80-color-manager.rules
polkit.addRule(function(action, subject) {
  if(action.id == "org.freedesktop.color-manager.create-device") {
    return polkit.Result.YES;
  }
});
EOF
"

sudo bash -c "cat <<EOF > /etc/dconf/db/local.d/01-fixes
[org/gnome/settings-daemon/plugins/xrandr]
default-monitors-setup='do-nothing'

[org/gnome/desktop/session]
idle-delay=uint32 0

[org/gnome/desktop/wm/preferences]
num-workspaces=1
EOF
"
sudo dconf update

echo "*** Configure demo user ***"
sudo bash -c "useradd demo
passwd -d demo
passwd -e demo
echo 'demo ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers

mkdir /home/demo/Desktop
for shortcut in firefox gnome-terminal; do
  install -m 0755 /usr/share/applications/\$shortcut.desktop /home/demo/Desktop
done
echo Path=/home/demo >>/home/demo/Desktop/gnome-terminal.desktop
chown -R demo:demo /home/demo/Desktop
"

sudo sed -i -e '/load-module.*bluetooth/ s/^/#/' /etc/pulse/default.pa
sudo sed -i -e 's/"dateMenu", //' /usr/share/gnome-shell/modes/classic.json

exit

SSH
