#!/usr/bin/python

import json
import random
import string
import sys

def key_val(pairs, key):
    for k in pairs:
       if k["Key"] == key:
          return k["Value"]
    return None

j = json.loads(sys.stdin.read())
for r in j:
   print r
