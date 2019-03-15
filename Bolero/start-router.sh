#!/bin/bash

# Script to connect to start zebra and bgpd in router
router=${1}
echo "Run zebra and bgpd in $router"

sudo python run.py --node $router --cmd "/usr/sbin/zebra -f conf/$router-zebra.conf -d -i /tmp/$router-zebra.pid > log/$router-zebra.log 2>&1"
sudo python run.py --node $router --cmd "/usr/sbin/bgpd -f conf/$router-bgpd.conf -d -i /tmp/$router-bgpd.pid > log/$router-bgpd.log 2>&1"