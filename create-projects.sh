#!/bin/bash

pwd_file=/etc/origin/master/users.htpasswd

. functions.sh

validate_config userlist "CSV file containing \"project names\", \"user names\", \"passwords\""
validate_config master "Please provide hostname for master. If --domain is set this should be a short name, rather than fully qualified"
optional_config pwd_file "location of htpasswd file, default $pwd_file"

declare -A projects

function parse_csv
{

  totproj=0
  while read line
  do
    OLDIFS=$IFS;
    IFS=, vals=($line)
    IFS=$OLDIFS

    projects[$totproj,0]=${vals[0]}
    projects[$totproj,1]=${vals[1]}
    projects[$totproj,2]=${vals[2]}

#    echo "read $totproj ${projects[0,0]}, ${projects[$totproj,0]}"

    let totproj++
    

  done < "${1}"

}

parse_csv $userlist

fqdn=$(gen_fqdn $master)

for pidx in $(seq 0 $(expr $totproj - 1))
do

  project=${projects[$pidx,0]}
  user=${projects[$pidx,1]}
  password=${projects[$pidx,2]}

  echo "Creating project $pidx $project, for user $user"

  scmd $ssh_user@$fqdn sudo htpasswd -b $pwd_file $user $password
  scmd $ssh_user@$fqdn sudo oadm new-project $project --admin $user "

done


