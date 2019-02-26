#!/usr/bin/env python

from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import info, setLogLevel
from mininet.cli import CLI
from mininet.node import Switch

from time import sleep, time
import sys
import os
import termcolor as T
import time

setLogLevel('info')


def log(s, col="green"):
    print T.colored(s, col)


class Router(Switch):
    """Defines a new router that is inside a network namespace so that the
    individual routing entries don't collide.

    """
    ID = 0

    def __init__(self, name, **kwargs):
        kwargs['inNamespace'] = True
        Switch.__init__(self, name, **kwargs)
        Router.ID += 1
        self.switch_id = Router.ID

    @staticmethod
    def setup():
        return

    def start(self, controllers):
        pass

    def stop(self):
        self.deleteIntfs()

    def log(self, s, col="magenta"):
        print T.colored(s, col)


class SimpleTopo(Topo):
    def __init__(self):
        # Add default members to class.
        super(SimpleTopo, self).__init__()
        BGPspeaker = self.addSwitch('BGPspeaker', dpid='1')  # a node that will announce routes using ExaBGP
        Quagga = self.addSwitch('Quagga', dpid='2')  # a node running quagga routing suite
        R = self.addSwitch('R', dpid='3')  # a node with ip_forward enabled
        h1 = self.addHost('h1')
        h2 = self.addHost('h2')
        self.addLink(BGPspeaker, Quagga)
        self.addLink(Quagga, R)
        self.addLink(Quagga, h1)
        self.addLink(R, h2)


def main():
    os.system("rm -f /tmp/R*.log /tmp/R*.pid logs/*")
    os.system("mn -c >/dev/null 2>&1")
    os.system("killall -9 zebra bgpd > /dev/null 2>&1")
    net = Mininet(topo=SimpleTopo(), switch=Router, controller=None)
    net.start()
    for router in net.switches:
        router.cmd("sysctl -w net.ipv4.ip_forward=1")
        router.waitOutput()

    log("Waiting %d seconds for sysctl changes to take effect..."
        % 3)
    sleep(3)

    # if someone ever gets curious about the interface names, by default, mininet names interfaces of a node with the format "<node name>-eth<n>" where n is the order the interface added, for a host, n starts from 0, for a switch, n starts from 1
    for s in net.switches:
        if s.name == "BGPspeaker":  # configure the BGP speaker
            s.cmd("ifconfig {}-eth1 10.0.0.1 netmask 255.255.255.0 ".format(s.name))  # this interface connects to the Quagga router
        elif s.name == "Quagga":  # configure Quagga
            s.cmd("/usr/sbin/zebra -f conf/zebra-{0}.conf -d -i /tmp/zebra-%s.pid > logs/{0}-zebra-stdout 2>&1".format(s.name))
            s.waitOutput()
            s.cmd("/usr/sbin/bgpd -f conf/bgpd-{0}.conf -d -i /tmp/bgp-{0}.pid > logs/{0}-bgpd-stdout 2>&1".format(s.name), shell=True)
            s.waitOutput()
            log("Starting zebra and bgpd on {}".format(s.name))
        else:  # configure R
            s.cmd("ifconfig {}-eth2 13.0.0.1 netmask 255.255.255.0 ".format(s.name))  # this interface connects to h2
            s.cmd("ifconfig {}-eth1 10.0.1.2 netmask 255.255.255.0 ".format(s.name))  # this interface connects to the Quagga router
    for host in net.hosts:
        host.cmd("ifconfig {}-eth0 1{}.0.0.2 netmask 255.255.255.0".format(host.name, int(host.name.split('h')[1])+1))
        host.cmd("route add default gw 1{}.0.0.1".format(int(host.name.split('h')[1])+1))

    CLI(net)
    net.stop()
    os.system("killall -9 zebra bgpd")


if __name__ == "__main__":
    main()
