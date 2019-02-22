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
        router = self.addSwitch('R1')
        h1 = self.addNode('h1')
        h2 = self.addNode('h2')
        self.addLink(router, h1)
        self.addLink(router, h2)


def getIP(hostname):
    if hostname == 'h1':
        ip = '192.168.1.110'
    else:
        ip = '192.168.2.110'
    return ip


def getGateway(hostname):
    if hostname == 'h1':
        gw = '192.168.1.1'
    else:
        gw = '192.168.2.1'
    return gw


def main():
    net = Mininet(topo=SimpleTopo(), switch=Router)
    net.start()
    for router in net.switches:
        router.cmd("sysctl -w net.ipv4.ip_forward=1")
        router.waitOutput()

    log("Waiting %d seconds for sysctl changes to take effect..."
        % 3)
    sleep(3)

    for router in net.switches:
        router.cmd("ifconfig R1-eth1 192.168.1.1 netmask 255.255.255.0 ")
        router.cmd("ifconfig R1-eth2 192.168.2.1 netmask 255.255.255.0 ")
    for host in net.hosts:
        host.cmd("ifconfig %s-eth0 %s" % (host.name, getIP(host.name)))
        host.cmd("route add default gw %s" % (getGateway(host.name)))

    CLI(net)
    net.stop()


if __name__ == "__main__":
    main()
