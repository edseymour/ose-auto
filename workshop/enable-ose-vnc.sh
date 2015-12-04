#!/bin/bash

. functions.sh

validate-config desktops "provide a list of desktop hosts"

for h in $desktops
do

   fqdn=$(gen_fqdn $h)

   scmd $ssh_user@$fqdn "sudo systemctl enable ose-vnc ; sudo systemctl start ose-vnc; sudo systemctl status ose-vnc"


done
