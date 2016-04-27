#!/bin/bash -x

. functions.sh

validate_config usercsv "provide a CSV file with ID,UserName,DesktopID,Project,Password,DesktopHost"
validate_config gitlab "provide hostname of gitlab server"
validate_config master "provide hostname of the OpenShift master"
optional_config skip_ose "skip openshift user creation"
optional_config skip_oc "skip openshift client config"
optional_config skip_desktop "skip desktop user creation"
optional_config skip_gitlab "skip gitlab user creation"
optional_config test_gitlab "run gitlab test"
optional_config test_ose "run ose test"
optional_config test_oc "run oc config test"
optional_config test_desktop "run desktop test"

master=$(gen_fqdn $master)

function git_proj
{
  echo "$1-monster"
}

function git_url
{
  echo "http://$gitlab/root/$(git_proj $1).git"
}

function preconfigure_oc
{
   user=$1
   desktop=$2

   scmd $ssh_user@$desktop sudo "bash -c \"mkdir /home/$user/.kube
cat >/home/$user/.kube/config <<EOF
kind: Config
apiVersion: v1
clusters:
- cluster:
    server: https://$master:8443
  name: ${master//./-}:8443
contexts:
- context:
    cluster: ${master//./-}:8443
  name: ${master//./-}:8443
current-context: ${master//./-}:8443
EOF
chown -R $user:$user /home/$user/.kube
   \" " < /dev/null
}

function provision_ose_user
{
   user=$1
   password=$2
   project=$3
   devproj="$3-dev"
   prodproj="$3-prod"

   giturl=$(git_url $project)

   echo "Creating OSE user $user, with projects $devproj and $prodproj, on $master"

   scmd $ssh_user@$master sudo "bash -c \"htpasswd -b /etc/origin/htpasswd $user $password ;
   oadm new-project $devproj --admin=$user ;
   oadm new-project $prodproj --admin=$user ;
   oc policy add-role-to-group system:image-puller system:serviceaccounts:$prodproj -n $devproj ;
   sed 's|##GITURL##|$giturl|g' /home/$ssh_user/monster-template.yaml |  oc create -n $devproj -f - ;
   sed 's/##DEV-PROJECT##/$devproj/g' /home/$ssh_user/monster-prod-template.yaml | oc create -n $prodproj -f - ;
    \" " < /dev/null
}

base_clone="http://ec2-54-76-190-81.eu-west-1.compute.amazonaws.com/root/monster.git"

function provision_gitlab_user
{
   user=$1
   password=$2
   project=$3
   gitp=$(git_proj $project)

   echo "Creating Gitlab user $user, with a project $gitp, on $gitlab"

   scmd $ssh_user@$gitlab "user=\$(gitlab user create --email $user@$gitlab --username $user --name $user --password $password --projects-limit 0 --can-create-group false --confirm false | head -n 1 | awk '{print \$2}')
   proj=\$(gitlab project create --name $gitp --issues-enabled false --wiki-enabled false --snippets-enabled false --public true --default-branch master --import-url $base_clone | head -n 1 | awk '{print \$2}')
   gitlab project-member create --project-id \$proj --user-id \$user --access-level 30
   
   " < /dev/null
}

importer_jar=com.redhat.importer_1.0.0.201509031446.jar 

function provision_desktop_user
{
   user=$1
   password=$2
   project=$3
   desktop=$4

   giturl=$(git_url $project)

   echo "Creating desktop user $user, with a project $project, on desktop $desktop"
   scmd $ssh_user@$desktop "sudo bash -c \"useradd $user
   echo ${password} | passwd ${user} --stdin 
   mkdir -p /home/$user/git
   pushd /home/$user/git
   git clone $giturl monster
   popd
   chown -R $user:$user /home/$user

   if [ ! -e /tmp/$importer_jar ]; then
      pushd /tmp
      curl -sLO https://github.com/jim-minter/eclipse-importer/raw/master/$importer_jar
      popd
   fi

   #cp /tmp/$importer_jar /usr/local/jbdevstudio/studio/plugins/
   #yum install -y xorg-x11-server-Xvfb
   #su - $user -c 'xvfb-run /usr/local/jbdevstudio/jbdevstudio -data workspace monster /home/$user/git/monster'
   #rm /usr/local/jbdevstudio/studio/plugins/$importer_jar 
  
   mkdir /home/$user/Desktop

   cat <<EOF >'/usr/share/applications/Red Hat JBoss Developer Studio 9.0.0.GA.desktop'
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

   install -m 0755 -o $user '/usr/share/applications/Red Hat JBoss Developer Studio 9.0.0.GA.desktop' /home/$user/Desktop
   install -m 0755 /usr/share/applications/firefox.desktop /home/$user/Desktop
   install -m 0755 /usr/share/applications/gnome-terminal.desktop /home/$user/Desktop
   echo Path=/home/$user >>/home/$user/Desktop/gnome-terminal.desktop
 
   chown -R $user:$user /home/$user

   \" " < /dev/null
}

function provision_desktop_users
{
   desktop=$1
   users=$2

   echo "Creating gnome greeter configuration for desktop $desktop"
   scmd $ssh_user@$desktop "sudo sed -i -e '/^\[greeter\]/ a \
IncludeAll=false\
Include=$users
/^\[xdmcp\]/ a \
Enable=true' /etc/gdm/custom.conf" < /dev/null

}

if [[ "$skip_ose" == "" ]] || [[ ! "$test_ose" == "" ]] 
then

  validate_config template_dir "please provide directory path for openshift templates  (monster and monster-prod)"

  sscp "$template_dir/monster-template.yaml" $ssh_user@$master:
  sscp "$template_dir/monster-prod-template.yaml" $ssh_user@$master:
fi


if [[ ! "$test_gitlab" == "" ]]; then

   provision_gitlab_user testuser redhat55 testuser

   read -p "press key to continue..."

fi


if [[ ! "$test_ose" == "" ]]; then

   provision_ose_user testuser redhat55 testuser

   read -p "press key to continue..."

fi

if [[ ! "$test_desktop" == "" ]]; then

   provision_desktop_user testuser redhat55 testuser ec2-54-72-148-213.eu-west-1.compute.amazonaws.com

   read -p "press key to continue..."
fi

if [[ ! "$test_oc" == "" ]]; then

   preconfigure_oc testuser ec2-54-72-148-213.eu-west-1.compute.amazonaws.com

   read -p "press key to continue..."
fi

declare -a desktopusers
declare -a desktophosts

IFS='
'

for line in $(tail -n +2 "$usercsv")
do
  OLDIFS=$IFS;
  IFS=, vals=($line)
  IFS=$OLDIFS

  id=${vals[0]}
  username=${vals[1]}
  desktopid=${vals[2]}
  project=${vals[3]}
  password=${vals[4]}
  desktophost=${vals[5]}

  echo "*********************
  User: $username Project: $project"

  [[ "$skip_ose" == "" ]] && provision_ose_user $username $password $project 

  [[ "$skip_gitlab" == "" ]] && provision_gitlab_user $username $password $project 

  [[ "$skip_desktop" == "" ]] && provision_desktop_user $username $password $project $desktophost

  [[ "$skip_oc" == "" ]] && preconfigure_oc $username $desktophost

  # insert comma if not first
  [[ ! "${desktopusers[$desktopid]}" == "" ]] && desktopusers[$desktopid]="${desktopusers[$desktopid]},"
  desktopusers[$desktopid]="${desktopusers[$desktopid]}$username"
  
  desktophosts[$desktopid]=$desktophost

done 



if [[ "$skip_desktop" == "" ]]
then

  for id in {1..20}
  do
    
    echo "*********************"
    provision_desktop_users ${desktophosts[$id]} "${desktopusers[$id]}"

  done

fi


if [[ "$skip_ose" == "" ]]; then

 echo "*******************************
 Bouncing the OpenShift master" 

 scmd $ssh_user@$master "sudo systemctl restart atomic-openshift-master"

fi
