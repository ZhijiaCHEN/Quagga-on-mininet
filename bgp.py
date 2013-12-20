
from mininet.topo import Topo
from mininet.net import Mininet
from mininet.log import lg, info, setLogLevel
from mininet.util import dumpNodeConnections, quietRun, moveIntf
from mininet.cli import CLI
from mininet.node import Switch, OVSKernelSwitch

from subprocess import Popen, PIPE, check_output
from time import sleep, time
from multiprocessing import Process
from argparse import ArgumentParser

import sys
import os
import termcolor as T
import time

setLogLevel('info')

parser = ArgumentParser("Configure simple BGP network in Mininet.")
parser.add_argument('--rogue', action="store_true", default=False)
args = parser.parse_args()

FLAGS_rogue_as = args.rogue

def log(s, col="green"):
    print T.colored(s, col)

class Router(Switch):
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
        super(SimpleTopo, self ).__init__()
        num_hosts_per_as = 3
        num_ases = 3
        num_hosts = num_hosts_per_as * num_ases
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

        if FLAGS_rogue_as:
            log("Adding rogue AS4", "magenta")
            routers.append(self.addSwitch('R4'))
            for j in xrange(num_hosts_per_as):
                hostname = 'h%d-%d' % (4, j)
                host = self.addNode(hostname)
                hosts.append(host)
                self.addLink('R4', hostname)
            # This MUST be added at the end
            self.addLink('R1', 'R4')
        return

def getIP(hostname):
    AS, idx = hostname.replace('h', '').split('-')
    AS = int(AS)
    if AS == 4:
        AS = 3
    ip = '%s.0.%s.1' % (10+AS, idx)
    return ip

def getGateway(hostname):
    AS, idx = hostname.replace('h', '').split('-')
    AS = int(AS)
    if AS == 4:
        AS = 3
    gw = '%s.0.%s.0' % (10+AS, idx)
    return gw

def main():
    os.system("rm -f /tmp/R*.log /tmp/R*.pid /tmp/*stdout*")
    net = Mininet(topo=SimpleTopo(), switch=Router)
    net.start()
    for router in net.switches:
        router.cmd("sysctl -w net.ipv4.ip_forward=1")
        router.waitOutput()
    sleep(3)
    for router in net.switches:
        router.cmd("/usr/lib/quagga/zebra -f zebra-%s.conf -d -i /tmp/zebra-%s.pid > /tmp/%s-zebra-stdout 2>&1" % (router.name, router.name, router.name))
        router.waitOutput()
        router.cmd("/usr/lib/quagga/bgpd -f bgpd-%s.conf -d -i /tmp/bgp-%s.pid > /tmp/%s-bgpd-stdout 2>&1" % (router.name, router.name, router.name), shell=True)
        router.waitOutput()
        log("Starting zebra and bgpd on %s" % router.name)

    for host in net.hosts:
        host.cmd("ifconfig %s-eth0 %s" % (host.name, getIP(host.name)))
        host.cmd("route add default gw %s" % (getGateway(host.name)))

    CLI(net)
    net.stop()
    os.system("killall -9 zebra bgpd")

if __name__ == "__main__":
    main()
