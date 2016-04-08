#!/usr/bin/python

import json
import random
import string
import sys

def key_val(pairs, key):
    for k in pairs:
       if k["Key"].startswith(key):
          return k["Value"]
    return "unknown"


j = json.loads(sys.stdin.read())
for r in j["Reservations"]:
    for i in r["Instances"]:
        if i["State"]["Name"] == "running":
            print '"' + '","'.join( [ key_val(i["Tags"],"Name"), i["NetworkInterfaces"][0]["PrivateIpAddresses"][0]["PrivateIpAddress"], i["NetworkInterfaces"][0]["PrivateIpAddresses"][0]["PrivateDnsName"], i["NetworkInterfaces"][0]["Association"]["PublicIp"], i["NetworkInterfaces"][0]["Association"]["PublicDnsName"]]) + '"'

