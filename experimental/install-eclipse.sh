#!/bin/bash

### copied from demobuilder

. functions.sh

validate_config target
validate_config jboss_installer

sscp $jboss_installer $ssh_user@$target:jboss-installer.jar

scmd $ssh_user@$target <<-\SSH

sudo mv jboss-installer.jar /root/

sudo subscription-manager repos --enable=rhel-7-server-optional-rpms --enable=rhel-server-rhscl-7-rpms

sudo yum install -y git unzip scl-utils maven30

sudo -i

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

cat <<EOF >"/usr/share/applications/Red Hat JBoss Developer Studio 9.0.0.GA.desktop"
[Desktop Entry]
Categories=Applications;Development;
Comment=Runs the Red Hat JBoss Developer Studio 9.0.0.GA
Comment[en]=Runs the Red Hat JBoss Developer Studio 9.0.0.GA
Encoding=UTF-8
Exec=/usr/local/jbdevstudio/studio/jbdevstudio
GenericName=
GenericName[en]=
Icon=/usr/local/jbdevstudio/studio/48-jbds_icon.png
MimeType=
Name=Red Hat JBoss Developer Studio 9.0.0.GA
Name[en]=Red Hat JBoss Developer Studio 9.0.0.GA
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

exit ; # exit sudo
exit ; # exit ssh

SSH
