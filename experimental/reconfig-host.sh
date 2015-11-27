#!/bin/bash

# used for reconfiguring system if the public hostname has changed (AWS restart an instance)

. functions.sh

validate_config target

sscp upload/* $ssh_user@$target:

scmd $ssh_user@$target <<-\SSH

sudo cp openshift-* /root/
sudo -i

./openshift-aws-reip.sh

exit;
exit;

SSH





