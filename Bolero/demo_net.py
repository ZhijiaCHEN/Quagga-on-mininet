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
    intfIPDict = {}
    linkEndDict = {}
    intfCntDict = {}
    linkCntDict = {0:0}
    routerASDict = {}
    routerIntfCntDict = {}
    bgpConnDict = {}
    bgpdTelnetAddress = {}
    def __init__(self):
        # Add default members to class.
        super(SimpleTopo, self).__init__()
        (Ra, Rb, Rc, Rd, Re, Rf, Bolero, BGP_agent) = ('Ra', 'Rb', 'Rc', 'Rd', 'Re', 'Rf', 'Bolero', 'BGP_agent')
        self.dpidDict = {Ra:"1", Rb:"2", Rc:"3", Rd:"4", Re:"5", Rf:"6", Bolero:"7", BGP_agent:"8"}
        self.quagga = [Ra, Rb, Rc, Rd, Re, Rf]
        self.bgpAgent = [Bolero, BGP_agent]
        self.routers = self.quagga+self.bgpAgent
        for r in self.routers:
            if r in self.quagga:
                self.addSwitch(r, dpid = self.dpidDict[r])
            else:
                self.addSwitch(r, dpid = self.dpidDict[r], notInNamespace=True)
        self.routerASDict = {Ra:3, Rb:3, Rc:3, Rd:3, Re:3, Rf:3, Bolero:3, BGP_agent:1}
        routerLinks = [(Ra, Rf), (Rb, Rf), (Rf, Rc), (Rf, Rd), (Rf, Re), (Ra, BGP_agent), (Rb, BGP_agent), (Ra, Bolero), (Rb, Bolero), (Rc, Bolero), (Rd, Bolero), (Re, Bolero), (Rf, Bolero)]
        for l in routerLinks:
            if l[0] not in self.bgpConnDict:
                self.bgpConnDict[l[0]] = []
            if l[1] not in self.bgpConnDict:
                self.bgpConnDict[l[1]] = []
            if (l[0] not in self.quagga) or (l[1] not in self.quagga): # In Bolero setup, every router has one and only one iBGP session which is with Bolero
                self.bgpConnDict[l[0]].append(l[1])
                self.bgpConnDict[l[1]].append(l[0])
            n1 = self.getIntfName(l[0])
            n2 = self.getIntfName(l[1])
            self.linkEndDict[n1] = n2
            self.linkEndDict[n2] = n1
            self.addLink(l[0], l[1], intfName1=n1, intfName2=n2)
            (self.intfIPDict[n1], self.intfIPDict[n2]) = self.getIntfPairIP(self.routerASDict[l[0]], self.routerASDict[l[1]])
            if l[0] == 'Bolero':
                self.bgpdTelnetAddress[l[1]] = self.intfIPDict[n2]
            if l[1] == 'Bolero':
                self.bgpdTelnetAddress[l[0]] = self.intfIPDict[n1]
            if l[0] in self.routerIntfCntDict:
                self.routerIntfCntDict[l[0]] += 1
            else:
                self.routerIntfCntDict[l[0]] = 1
            if l[1] in self.routerIntfCntDict:
                self.routerIntfCntDict[l[1]] += 1
            else:
                self.routerIntfCntDict[l[1]] = 1
    def getIntfName(self, router):
        if router in self.intfCntDict:
            self.intfCntDict[router] += 1
        else:
            self.intfCntDict[router] = 1
        return "{}-eth{}".format(router, self.intfCntDict[router])
    
    def getIntfPairIP(self, AS1, AS2):
        if AS1 == AS2: # interior link
            if AS1 in self.linkCntDict:
                ip1 = '{}.0.0.{}'.format(100+AS1, 1+4*self.linkCntDict[AS1])
                ip2 = '{}.0.0.{}'.format(100+AS1, 2+4*self.linkCntDict[AS1])
                self.linkCntDict[AS1] += 1
            else:
                ip1 = '{}.0.0.{}'.format(100+AS1, 1)
                ip2 = '{}.0.0.{}'.format(100+AS1, 2)
                self.linkCntDict[AS1] = 1
        else: # exterior link
            ip1 = '10.0.0.{}'.format(1+4*self.linkCntDict[0])
            ip2 = '10.0.0.{}'.format(2+4*self.linkCntDict[0])
            self.linkCntDict[0] += 1
        return (ip1, ip2)



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

    for router in topo.quagga:
        intfConfStr = "interface lo\n  ip address 127.0.0.1/32\n"
        for i in range(topo.routerIntfCntDict[router]):
            intf = "{}-eth{}".format(router, i+1)
            intfConfStr += "interface {}\n  ip address {}/30\n".format(intf, topo.intfIPDict[intf])
        f = open("conf/{}-zebra.conf".format(router), 'w')
        f.write(confTemplate.format(intfConfStr, router))
        f.close()

def genBgpdConf(topo):
    for router in topo.quagga:
        localAS = topo.routerASDict[router]
        idx = topo.dpidDict[router]
        f = open("conf/{}-bgpd.conf".format(router), 'w')
        f.write("! -*- bgp -*-\nhostname {0}\npassword en\nenable password en\n\nrouter bgp {1}\n  bgp router-id {2}.0.0.{3}\n  !network {2}.{3}.0.0/16\n!redistribute ospf\n\n".format(router, localAS, localAS+100, idx))
        boleroInfo = ""
        for i in range(topo.routerIntfCntDict[router]):
            intf = "{}-eth{}".format(router, i+1)
            if intf not in topo.linkEndDict:
                continue
            nIntf = topo.linkEndDict[intf]
            nRouter = nIntf.split('-')[0]
            if nRouter not in topo.bgpConnDict[router]: continue
            remoteAS = topo.routerASDict[nRouter]
            remoteAddress = topo.intfIPDict[nIntf]
            f.write("  neighbor {0} remote-as {1}\n  neighbor {0} next-hop-self\n  neighbor {0} timers 5 5\n\n".format(remoteAddress, remoteAS))
            if nRouter == "Bolero": # Bolero communicates with quagga routers through R4
                boleroInfo = "bolero address {}\nbolero port 5432\nbolero user bolero\nbolero password bolero\nbolero\n\n".format(remoteAddress)
        f.write(boleroInfo)
        f.write("debug bgp as4\ndebug bgp events\ndebug bgp filters\ndebug bgp fsm\ndebug bgp keepalives\ndebug bgp updates\n\nlog file /tmp/{}-bgpd.log\n\n".format(router))
        f.close()

def genOspfdConf(topo):
    for router in topo.quagga:
        localAS = topo.routerASDict[router]
        idx = topo.dpidDict[router]
        f = open("conf/{}-ospfd.conf".format(router), 'w')
        f.write("! -*- ospf -*-\nhostname {0}\npassword en\nenable password en\n\nrouter ospf\n  ospf router-id {1}.0.0.{2}\n!  redistribute bgp\n\n".format(router, localAS+100, idx))
        for i in range(topo.routerIntfCntDict[router]):
            intf = "{}-eth{}".format(router, i+1)
            address = topo.intfIPDict[intf]
            f.write("  network {0}/30 area 0\n\n".format(address))
        f.write("debug ospf zebra\ndebug ospf event\n\nlog file /tmp/{}-ospfd.log\n".format(router))
        f.close()

def main():
    os.system("rm -f /tmp/R*.log /tmp/R*.pid log/*")
    os.system("mn -c >/dev/null 2>&1")
    os.system("killall -9 zebra ospfd bgpd > /dev/null 2>&1")
    os.system('pgrep -f webserver.py | xargs kill -9')
    topo = SimpleTopo()
    genZebraConf(topo)
    genOspfdConf(topo)
    genBgpdConf(topo)
    net = Mininet(topo=topo, switch=Router, controller=None)
    net.start()
    for router in net.switches:
        router.cmd("sysctl -w net.ipv4.ip_forward=1")
        router.waitOutput()

    log("Waiting 3 seconds for sysctl changes to take effect...")
    sleep(3)

    for router in net.switches:
        if router.name in topo.bgpAgent:
            #router for routes injection
            for i in range(topo.routerIntfCntDict[router.name]):
                intf = "{}-eth{}".format(router.name, i+1)
                if intf not in topo.linkEndDict:
                    continue
                nIntf = topo.linkEndDict[intf]
                nRouter = nIntf.split('-')[0]
                localAS = topo.routerASDict[router.name]
                localAddress = topo.intfIPDict[intf]
                remoteAS = topo.routerASDict[nRouter]
                remoteAddress = topo.intfIPDict[nIntf]
                router.cmd("ifconfig {} {}/30".format(intf, localAddress))
                router.cmd('/home/zhijia/miniconda3/bin/python /home/zhijia/git/yabgp/bin/yabgpd --bgp-local_addr={0} --bgp-local_as={1} --bgp-remote_addr={2} --bgp-remote_as={3} --rest-bind_host={0}  2>/home/zhijia/git/Quagga-on-mininet/Bolero/yabgp-api-{4}.log &'.format(localAddress, localAS, remoteAddress, remoteAS, router.name))

    # all interfaces of bgp agent must be configured before starting quagga routers, otherwise quagga could not connect to Bolero
    xterms = []

    for router in net.switches:
        if router.name in topo.quagga:
            router.cmd("/home/zhijia/quagga-etc/sbin/zebra -f conf/{0}-zebra.conf -d -i /tmp/{0}-zebra.pid > log/{0}-zebra.log 2>&1".format(router.name), shell=True)
            router.waitOutput()
            router.cmd("/home/zhijia/quagga-etc/sbin/ospfd -f conf/{0}-ospfd.conf -d -i /tmp/{0}-ospfd.pid > log/{0}-ospfd.log 2>&1".format(router.name), shell=True)
            router.waitOutput()
            router.cmd("/home/zhijia/quagga-etc/sbin/bgpd -f conf/{0}-bgpd.conf -d -i /tmp/{0}-bgp.pid > log/{0}-bgpd.log 2>&1".format(router.name), shell=True)
            router.waitOutput()
            log("Starting zebra ospfd, bgpd on {}".format(router.name))
            bgpdConnCmd = 'xterm -T "{}" -e python2 telnet.py {}'.format(router.name, topo.bgpdTelnetAddress[router.name])
            p = subprocess.Popen(bgpdConnCmd,
                             shell=True,
                             stdin=subprocess.PIPE,
                             stdout=subprocess.PIPE)
            xterms.append(p)

    for host in net.hosts:
        host.cmd("ifconfig {}-eth0 {}".format(host.name, getHostIP(host.name)))
        host.cmd("route add default gw {}".format(getGateway(host.name)))
    tables = ['rib_in','routing_decision']
    for t in tables:
        xtermCmd = 'xterm -T "{0}" -e python watch_table.py {0}'.format(t)
        p = subprocess.Popen(xtermCmd,
                            shell=True,
                            stdin=subprocess.PIPE,
                            stdout=subprocess.PIPE)
        xterms.append(p)

    CLI(net)
    net.stop()
    for r in topo.quagga:
        os.system("wmctrl -lp | awk '/{}/{{print $3}}' | xargs kill".format(r))
    for t in tables:
        os.system("wmctrl -lp | awk '/{}/{{print $3}}' | xargs kill".format(t))
        
    
    #os.system("killall -9 zebra ospfd bgpd")


if __name__ == "__main__":
    main()
