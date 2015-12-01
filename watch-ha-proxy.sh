#!/bin/bash

for node in node01 node02
do
ssh $node <<-\EOF

export interface=${interface:-"eth0"}
echo "Check multicast enabled ... ";
ifconfig $interface | grep -i MULTICAST

echo "Check multicast groups ... "
netstat -g -n | grep 224.0.0 | grep $interface

echo "Optionally, add accept rule and persist it ... "
/sbin/iptables -I INPUT -i $interface -d 224.0.0.18/32 -j ACCEPT

echo "Ensuring the above rule is added on system restarts."

/usr/sbin/iptables-save > /etc/sysconfig/iptables

EOF
done;
[root@ip-192-168-125-190 ansible]# cat /root/watch-ha-proxy
#!/bin/bash

pod1=$(oc get pods --selector='router=ha-router' --template='{{with index .items 0}}{{.metadata.name}}{{end}}')
pod2=$(oc get pods --selector='router=ha-router' --template='{{with index .items 1}}{{.metadata.name}}{{end}}')

cmd="echo 'show stat' | socat - UNIX-CONNECT:/var/lib/haproxy/run/haproxy.sock"

wc1="oc exec $pod1 -- bash -c \"$cmd\""
wc2="oc exec $pod2 -- bash -c \"$cmd\""

watch -n 5 -d "$wc1 && $wc2"
