#!/bin/bash

. functions.sh

validate_config installer_file "please provide an OC installer file"
validate_config desktops "provide a list of desktop hosts"

for h in $desktops
do

   fqdn=$(gen_fqdn $h)

   sscp "$installer_file" $ssh_user@$fqdn:oc-package.tar.gz

   scmd $ssh_user@$fqdn "sudo tar -xf oc-package.tar.gz -C /usr/bin/"

done

