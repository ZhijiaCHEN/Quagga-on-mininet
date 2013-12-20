
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import lg, info, setLogLevel
from mininet.util import dumpNodeConnections, quietRun, moveIntf
from mininet.cli import CLI
from mininet.node import Switch

from subprocess import Popen, PIPE, check_output
from time import sleep, time
from multiprocessing import Process
from argparse import ArgumentParser

import sys
import os
import termcolor as T
import time

setLogLevel('info')

CONTROL_IFACES=["eth0", "lo"]
parser = ArgumentParser("Configure simple BGP network in Mininet.")
parser.add_argument('--num-ases', type=int, default=3)
parser.add_argument('--num-hosts-per-as', type=int, default=3)
args = parser.parse_args()

def log(s, col="green"):
    print T.colored(s, col)

class Router(Switch):
    ID = 0
    def __init__(self, name, **kwargs):
        kwargs['inNamespace'] = True
        Switch.__init__(self, name, **kwargs)
        print "Switch %s %s" % (name, self.inNamespace)
        Router.ID += 1
        self.switch_id = Router.ID

    @staticmethod
    def setup():
        pass

    def start(self, controllers):
        # Initialise
        self.cmd("sysctl -w net.ipv4.ip_forward=1")
        self.cmd("ifconfig %s-eth1 0" % (self.name))
        ip = None
        cmd = "ifconfig %s-eth1 %s" % (self.name, ip)
        self.cmd(cmd)

    def stop(self):
        self.deleteIntfs()

    def log(self, s, col="magenta"):
        print T.colored(s, col)

class SimpleTopo(Topo):
    def __init__(self, num_ases=args.num_ases, num_hosts_per_as=args.num_hosts_per_as):
        # Add default members to class.
        super(SimpleTopo, self ).__init__()
        num_hosts = num_hosts_per_as * num_ases
        self.num_hosts = num_hosts
        # The topology has one router per AS
	routers = []
        for i in xrange(num_ases):
            router = self.addSwitch('R%d' % (i+1))
	    routers.append(router)

	hosts = []
        for i in xrange(num_ases):
            router = 'R%d' % (i+1)
            for j in xrange(num_hosts_per_as):
                hostname = 'h%d-%d' % (i+1, j+1)
                host = self.addNode(hostname)
                hosts.append(host)
                self.addLink(router, host)

        for i in xrange(num_ases-1):
            self.addLink('R%d' % (i+1), 'R%d' % (i+2))
        return

def getIP(hostname):
    AS, idx = hostname.replace('h', '').split('-')
    ip = '%s.0.0.%s' % (10+int(AS), idx)
    print hostname, ip
    return ip

def main():
    net = Mininet(topo=SimpleTopo(), switch=Router)
    net.start()
    for id, host in enumerate(net.hosts):
        getIP(host.name)

    CLI(net)
    net.stop()

if __name__ == "__main__":
    main()
