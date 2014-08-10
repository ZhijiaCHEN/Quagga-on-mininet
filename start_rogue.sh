#!/bin/bash

echo "Killing rogue AS"
./stop_rogue.sh

sudo python run.py --node R4 --cmd "/usr/lib/quagga/zebra -f conf/zebra-R4.conf -d -i /tmp/zebra-R4.pid > logs/R4-zebra-stdout"
sudo python run.py --node R4 --cmd "/usr/lib/quagga/bgpd -f conf/bgpd-R4.conf -d -i /tmp/bgpd-R4.pid > logs/R4-bgpd-stdout"
