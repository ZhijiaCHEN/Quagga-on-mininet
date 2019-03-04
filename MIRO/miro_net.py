#!/usr/bin/env python

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
import subprocess

setLogLevel('info')


def log(s, col="green"):
    print T.colored(s, col)


class Router(Switch):
    """Defines a new router that is inside a network namespace so that the
    individual routing entries don't collide.

    """
    ID = 0

    def __init__(self, name, **kwargs):
        if 'notInNamespace' not in kwargs:
            kwargs['inNamespace'] = True
        else:
            kwargs.pop('notInNamespace')
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
    intfCnt = 0
    intfDict = {}
    linkEndDict = {}

    def __init__(self):
        # Add default members to class.
        super(SimpleTopo, self).__init__()
        R3_1 = self.addSwitch('R3_1')
        R3_2 = self.addSwitch('R3_2')
        R3_3 = self.addSwitch('R3_3')
        R1_1 = self.addSwitch('R1_1', notInNamespace=True)
        self.routers = [R3_1, R3_2, R3_3, R1_1]
        routerLinks = [(R3_1, R3_3, 'I'), (R3_2, R3_3, 'I'), (R1_1, R3_1, 'E'), (R1_1, R3_2, 'E')]
        for l in routerLinks:
            n1 = self.getIntfName(l[0], l[2])
            n2 = self.getIntfName(l[1], l[2])
            self.linkEndDict[n1] = n2
            self.linkEndDict[n2] = n1
            self.addLink(l[0], l[1], intfName1=n1, intfName2=n2)
        #        R1_1 = self.addSwitch('R1_1')
        #        R2_1 = self.addSwitch('R2_1')
        #        R3_1 = self.addSwitch('R3_1')
        #        R4_1 = self.addSwitch('R4_1')
        #        R5_1 = self.addSwitch('R5_1')
        #        R5_2 = self.addSwitch('R5_2')
        #        R5_3 = self.addSwitch('R5_3')
        #        R6_1 = self.addSwitch('R6_1')
        #        R7_1 = self.addSwitch('R7_1', notInNamespace=True)
        #        self.routers = [R1_1, R2_1, R3_1, R4_1, R5_1, R5_2, R5_3, R6_1, R7_1]
        #        h1_1 = self.addHost('h1_1')
        #        h6_1 = self.addHost('h6_1')
        #        routerLinks = [(R1_1, R2_1, 'E'), (R1_1, R3_1, 'E'), (R3_1, R4_1, 'E'), (R2_1, R5_1, 'E'), (R4_1, R5_2, 'E'), (R5_2, R5_3, 'I'),
        #                    (R5_3, R5_1, 'I'), (R5_3, R6_1, 'E'), (R5_3, R7_1, 'E'), (R5_2, R7_1, 'E'), (R5_1, R7_1, 'E')]
        #        for l in routerLinks:
        #            n1 = self.genIntfName(l[0], l[2])
        #            n2 = self.genIntfName(l[1], l[2])
        #            self.linkEndDict[n1] = n2
        #            self.linkEndDict[n2] = n1
        #            self.addLink(l[0], l[1], intfName1=n1, intfName2=n2)
        #        self.addLink(R1_1, h1_1, intfName1=self.genIntfName(R1_1, 'G'))
        #        self.addLink(R6_1, h6_1, intfName1=self.genIntfName(R6_1, 'G'))

    def getIntfName(self, router, orient):
        self.intfCnt += 1
        intfName = '{}-{}-eth{}'.format(router, orient, self.intfCnt)
        #print("create interface {} for router {}".format(intfName, router))
        if router in self.intfDict:
            self.intfDict[router].append(intfName)
        else:
            self.intfDict[router] = [intfName]
        return intfName


def getHostIP(hostname):
    AS, idx = hostname.replace('h', '').split('_')
    AS = int(AS)
    idx = int(idx)
    ip = '{}.1.0.{}/24'.format(AS+100, idx+1)
    return ip


def getGateway(hostname):
    AS, idx = hostname.replace('h', '').split('_')
    AS = int(AS)
    gw = '{}.1.0.1'.format(AS+100)
    return gw


def getIntfIP(intfName, maskLen=30):
    AS = int(intfName.replace("R", "").split('_')[0])
    intfIdx = int(intfName.split('eth')[1])
    orient = intfName.split('-')[1]
    if maskLen:
        ip = "/{}".format(maskLen)
    else:
        ip = ""
    if orient == 'G':
        ip = '{}.1.0.1'.format(AS+100) + ip
    elif orient == 'I':
        ip = '{}.0.0.{}'.format(AS+100, 1+((intfIdx-1)/2)*4+((intfIdx-1) % 2)) + ip  # This is to make each pair of interfaces between routers inside a 2 bits subnet
    elif orient == 'E':
        ip = '10.0.0.{}'.format(1+((intfIdx-1)/2)*4+((intfIdx-1) % 2)) + ip  # This is to make each pair of interfaces between routers inside a 2 bits subnet
    else:
        assert False, "unknown type of interface!"
    #print("assign ip {} to intface {}".format(ip, intfName))
    return ip


def genZebraConf(topo):
    confTemplate = """
! -*- zebra -*-

hostname R1
password en
enable password en

! interface configuration
{}

!
log file /tmp/{}-zebra.log
"""

    for router in topo.routers:
        intfConfStr = "interface lo\n  ip address 127.0.0.1/32\n"
        for intf in topo.intfDict[router]:
            intfConfStr += "interface {}\n  ip address {}\n".format(intf, getIntfIP(intf))
        f = open("conf/{}-zebra.conf".format(router), 'w')
        f.write(confTemplate.format(intfConfStr, router))
        f.close()


def genBgpdConf(topo):
    for router in topo.routers:
        AS, idx = router.replace("R", "").split("_")
        AS = int(AS)
        idx = int(idx)
        f = open("conf/{}-bgpd.conf".format(router), 'w')
        f.write("! -*- bgp -*-\nhostname {0}\npassword en\nenable password en\n\nrouter bgp {1}\n  bgp router-id {2}.0.0.{3}\n  network {2}.{3}.0.0/16\n".format(router, AS, AS+100, idx))
        for intf in topo.intfDict[router]:
            if intf not in topo.linkEndDict:
                continue
            nIntf = topo.linkEndDict[intf]
            nAS = int(nIntf.split('-')[0].replace("R", "").split("_")[0])
            nIP = getIntfIP(nIntf, maskLen=None)
            f.write("  neighbor {0} remote-as {1}\n  neighbor {0} next-hop-self\n  neighbor {0} timers 5 5\n".format(nIP, nAS))
        f.write("debug bgp as4\ndebug bgp events\ndebug bgp filters\ndebug bgp fsm\ndebug bgp keepalives\ndebug bgp updates\n!\nlog file /tmp/{}-bgpd.log\n\n".format(router))
        f.close()


def main():
    os.system("rm -f /tmp/R*.log /tmp/R*.pid log/*")
    os.system("mn -c >/dev/null 2>&1")
    os.system("killall -9 zebra bgpd > /dev/null 2>&1")
    os.system('pgrep -f webserver.py | xargs kill -9')
    topo = SimpleTopo()
    #genZebraConf(topo)
    #genBgpdConf(topo)
    net = Mininet(topo=topo, switch=Router, controller=None)
    net.start()
    for router in net.switches:
        router.cmd("sysctl -w net.ipv4.ip_forward=1")
        router.waitOutput()

    log("Waiting 3 seconds for sysctl changes to take effect...")
    sleep(3)

    for router in net.switches:
        # if router.name == "R5_2":
        #    continue  # we will start R5_2 manually later
        if router.name == "R1_1":
            # a routes injection point
            for intf in topo.intfDict[router.name]:
                if intf not in topo.linkEndDict:
                    continue
                router.cmd("ifconfig {} {}".format(intf, getIntfIP(intf)))
                router.cmd('/home/zhijia/miniconda3/bin/python /home/zhijia/git/yabgp/bin/yabgpd --bgp-local_addr={0} --bgp-local_as=1 --bgp-remote_addr={1} --bgp-remote_as=3 --rest-bind_host={0}  2>/home/zhijia/git/Quagga-on-mininet/MIRO/yabgp-api-{2}.log &'.format(getIntfIP(intf, maskLen=None), getIntfIP(topo.linkEndDict[intf], maskLen=None), intf))
            continue

        router.cmd("/usr/sbin/zebra -f conf/{0}-zebra.conf -d -i /tmp/{0}-zebra.pid > log/{0}-zebra.log 2>&1".format(router.name), shell=True)
        router.waitOutput()
        router.cmd("/usr/sbin/bgpd -f conf/{0}-bgpd.conf -d -i /tmp/{0}-bgp.pid > log/{0}-bgpd.log 2>&1".format(router.name), shell=True)
        router.waitOutput()
        log("Starting zebra and bgpd on {}".format(router.name))

    for host in net.hosts:
        host.cmd("ifconfig {}-eth0 {}".format(host.name, getHostIP(host.name)))
        host.cmd("route add default gw {}".format(getGateway(host.name)))

    CLI(net)
    net.stop()
    os.system("killall -9 zebra bgpd")


if __name__ == "__main__":
    main()
